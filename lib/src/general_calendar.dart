import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'calendar_attributes.dart';
import 'calendar_design.dart';
import 'calendar_selection.dart';
import 'calendar_theme.dart';

/// Keeps the intrinsic calendar height while a horizontal viewport pages
/// between months with different row counts.
class _MonthPager extends StatefulWidget {
  const _MonthPager({
    super.key,
    required this.page,
    required this.pageCount,
    required this.enableSwipeNavigation,
    required this.duration,
    required this.onPageChanged,
    required this.heightForPage,
    required this.builder,
  });

  final int page;
  final int pageCount;
  final bool enableSwipeNavigation;
  final Duration duration;
  final ValueChanged<int> onPageChanged;
  final double Function(int) heightForPage;
  final Widget Function(int) builder;

  @override
  State<_MonthPager> createState() => _MonthPagerState();
}

class _MonthPagerState extends State<_MonthPager> {
  late final PageController _controller;
  int _navigation = 0;
  int? _targetPage;
  late int _reportedPage;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.page, keepPage: false);
    _reportedPage = widget.page;
  }

  @override
  void didUpdateWidget(_MonthPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.page == oldWidget.page &&
        !(widget.duration == Duration.zero && _targetPage != null)) {
      return;
    }
    // A drag already moved the controller before notifying the parent.
    if (_targetPage == null && _reportedPage == widget.page) return;
    _scrollToPage();
  }

  Future<void> _scrollToPage() async {
    final navigation = ++_navigation;
    _targetPage = widget.page;
    if (widget.duration == Duration.zero) {
      _controller.jumpToPage(widget.page);
    } else {
      await _controller.animateToPage(
        widget.page,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted && navigation == _navigation) _targetPage = null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollBehavior = ScrollConfiguration.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final page = (_controller.hasClients
                ? _controller.page ?? widget.page.toDouble()
                : widget.page.toDouble())
            .clamp(0.0, (widget.pageCount - 1).toDouble());
        final start = page.floor();
        final end = page.ceil();
        final startHeight = widget.heightForPage(start);
        final endHeight = widget.heightForPage(end);
        return SizedBox(
          height: startHeight + (endHeight - startHeight) * (page - start),
          child: child,
        );
      },
      child: ScrollConfiguration(
        behavior: scrollBehavior.copyWith(
          dragDevices: {...scrollBehavior.dragDevices, PointerDeviceKind.mouse},
        ),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth != 0) return false;
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              ++_navigation;
              _targetPage = null;
            }
            if (notification is ScrollEndNotification && _targetPage == null) {
              final page = _controller.page!.round();
              if (page != widget.page) widget.onPageChanged(page);
            }
            return false;
          },
          child: PageView.builder(
            key: const ValueKey('general-calendar-month-pager'),
            controller: _controller,
            physics: widget.enableSwipeNavigation
                ? const PageScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: widget.pageCount,
            onPageChanged: (index) {
              _reportedPage = index;
              if (_targetPage == null && index != widget.page) {
                widget.onPageChanged(index);
              }
            },
            itemBuilder: (context, index) => IgnorePointer(
              ignoring: index != widget.page,
              child: ExcludeSemantics(
                excluding: index != widget.page,
                child: ExcludeFocus(
                  excluding: index != widget.page,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: widget.heightForPage(index),
                    maxHeight: widget.heightForPage(index),
                    // Let ensureVisible reveal a day vertically while the outer
                    // pager aligns the entire month, rather than the day's cell.
                    child: SingleChildScrollView(
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      child: widget.builder(index),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    this.design = GeneralCalendarDesign.material,
    this.visibleMonths,
    this.enableSwipeNavigation = true,
    this.animationDuration = const Duration(milliseconds: 250),
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
    if (visibleMonths != null && visibleMonths != 1 && visibleMonths != 2) {
      throw ArgumentError.value(visibleMonths, 'visibleMonths', 'Use 1 or 2.');
    }
    if (animationDuration.isNegative) {
      throw ArgumentError.value(animationDuration, 'animationDuration');
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
  final GeneralCalendarDesign design;

  /// One or two consecutive month panels. Two panels collapse to one below
  /// 760 logical pixels and at the last allowed month. Null uses the design's
  /// preference. Week and year views always use one panel.
  final int? visibleMonths;

  /// Enables horizontal touch, trackpad, and mouse dragging between months.
  /// Navigation follows the ambient text direction and respects date bounds.
  final bool enableSwipeNavigation;

  /// Duration of month navigation triggered by the header controls.
  /// Set to [Duration.zero] for immediate navigation. The platform's reduced
  /// motion setting also disables these animations.
  final Duration animationDuration;
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
    final theme = widget.design
        .resolve(Theme.of(context))
        .merge(GeneralCalendarTheme.of(context))
        .merge(widget.theme);
    final radius = BorderRadius.circular(theme.surfaceRadius ?? 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final requestedMonths =
            widget.visibleMonths ?? widget.design.preferredVisibleMonths;
        DateTime? secondMonthFor(DateTime anchor) =>
            _view == GeneralCalendarView.month &&
                    requestedMonths == 2 &&
                    constraints.maxWidth >= 760 &&
                    _delegate.monthDelta(anchor, widget.lastDate) > 0
                ? _delegate.addMonthsToMonthDate(anchor, 1)
                : null;
        final secondMonth = secondMonthFor(_displayed);
        Widget panel(DateTime anchor, {bool multiMonth = false}) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWeekdays(localizations, theme),
                ..._buildDays(context, localizations, theme,
                    anchor: anchor, multiMonth: multiMonth),
              ],
            );
        Widget monthPanels(DateTime anchor) {
          final second = secondMonthFor(anchor);
          if (second == null) return panel(anchor);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: panel(anchor, multiMonth: true)),
              const SizedBox(width: 24),
              Expanded(child: panel(second, multiMonth: true)),
            ],
          );
        }

        DateTime monthAt(int index) =>
            _delegate.addMonthsToMonthDate(widget.firstDate, index);
        double monthHeight(DateTime anchor) {
          final month = _delegate.getMonth(anchor.year, anchor.month);
          final offset = widget.firstDayOfWeek == null
              ? _delegate.firstDayOffset(month.year, month.month, localizations)
              : _weekOffset(month, localizations);
          final rows = (offset +
                  _delegate.getDaysInMonth(month.year, month.month) +
                  6) ~/
              7;
          return 32 + rows * theme.dayHeight;
        }

        return Material(
          key: ValueKey('general-calendar-surface-${widget.design.name}'),
          color: theme.surfaceColor,
          elevation: theme.elevation ?? 0,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: theme.showBorder == true
                ? BorderSide(color: theme.borderColor!)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: theme.contentPadding ?? EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, localizations, theme, secondMonth),
                if (theme.showHeaderDivider == true)
                  Divider(height: 1, color: theme.borderColor),
                if (_view == GeneralCalendarView.year)
                  _buildYear(context, localizations, theme)
                else if (_view == GeneralCalendarView.month)
                  _MonthPager(
                    key: ValueKey((
                      _delegate,
                      widget.firstDate,
                      widget.lastDate,
                    )),
                    page: _delegate.monthDelta(widget.firstDate, _displayed),
                    pageCount: _delegate.monthDelta(
                            widget.firstDate, widget.lastDate) +
                        1,
                    enableSwipeNavigation: widget.enableSwipeNavigation,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : widget.animationDuration,
                    onPageChanged: (index) =>
                        _setDisplayed(_clamp(monthAt(index))),
                    heightForPage: (index) {
                      final month = monthAt(index);
                      final second = secondMonthFor(month);
                      final height = monthHeight(month);
                      if (second == null) return height;
                      final secondHeight = monthHeight(second);
                      return height > secondHeight ? height : secondHeight;
                    },
                    builder: (index) => monthPanels(monthAt(index)),
                  )
                else
                  panel(_displayed),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, MaterialLocalizations localizations,
      GeneralCalendarThemeData theme, DateTime? secondMonth) {
    final layout = theme.headerLayout ?? CalendarHeaderLayout.leading;
    Widget title(DateTime date, {bool centered = false}) => Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              _view == GeneralCalendarView.year
                  ? _delegate.formatYear(date.year, localizations)
                  : _delegate.formatMonthYear(date, localizations),
              textAlign: centered ? TextAlign.center : TextAlign.start,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.headerTextStyle,
            ),
          ),
        );
    final switcher = widget.showViewSwitcher
        ? PopupMenuButton<GeneralCalendarView>(
            key: const ValueKey('general-calendar-view'),
            tooltip: widget.labels.chooseView,
            color: theme.surfaceColor,
            icon: Icon(Icons.calendar_view_month,
                color: theme.mutedForegroundColor),
            onSelected: _setView,
            itemBuilder: (context) => [
              for (final view in GeneralCalendarView.values)
                PopupMenuItem(value: view, child: Text(_viewLabel(view))),
            ],
          )
        : const SizedBox.shrink();
    Widget navigation(int direction) {
      final outlined =
          theme.navigationStyle == CalendarNavigationStyle.outlined;
      final filled = theme.navigationStyle == CalendarNavigationStyle.filled;
      return IconButton(
        key: ValueKey(direction < 0
            ? 'general-calendar-previous'
            : 'general-calendar-next'),
        tooltip: direction < 0
            ? localizations.previousPageTooltip
            : localizations.nextPageTooltip,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular((theme.dayRadius ?? 4).clamp(0, 12)),
          )),
          side: WidgetStatePropertyAll(outlined
              ? BorderSide(color: theme.borderColor!)
              : BorderSide.none),
          foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? theme.mutedForegroundColor?.withValues(alpha: 0.38)
                  : widget.design == GeneralCalendarDesign.cupertino
                      ? theme.todayColor
                      : theme.foregroundColor),
          backgroundColor: WidgetStatePropertyAll(
              filled ? theme.borderColor?.withValues(alpha: 0.3) : null),
        ),
        onPressed: _canNavigate(direction, localizations)
            ? () => _navigate(direction, localizations)
            : null,
        icon: Icon(direction < 0 ? Icons.chevron_left : Icons.chevron_right,
            size: 20),
      );
    }

    final previous = navigation(-1);
    final next = navigation(1);
    final Widget header;
    if (secondMonth != null) {
      // Match the panel widths and gutter below. Controls overlay the reserved
      // title padding so their widths cannot shift either month heading.
      header = Stack(alignment: Alignment.center, children: [
        Row(children: [
          for (final date in [_displayed, secondMonth]) ...[
            if (date == secondMonth) const SizedBox(width: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: title(date, centered: true),
              ),
            ),
          ],
        ]),
        Align(alignment: AlignmentDirectional.centerStart, child: previous),
        Align(alignment: AlignmentDirectional.centerEnd, child: next),
        if (widget.showViewSwitcher) switcher,
      ]);
    } else {
      header = switch (layout) {
        CalendarHeaderLayout.leading => Row(children: [
            Expanded(child: title(_displayed)),
            switcher,
            previous,
            next
          ]),
        CalendarHeaderLayout.centered => Row(children: [
            previous,
            Expanded(child: title(_displayed, centered: true)),
            next,
            switcher
          ]),
        CalendarHeaderLayout.split => Row(children: [
            previous,
            Expanded(child: title(_displayed, centered: true)),
            switcher,
            next
          ]),
        CalendarHeaderLayout.stacked =>
          Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [Expanded(child: title(_displayed)), switcher]),
            Row(children: [
              previous,
              next,
              const Spacer(),
              TextButton(
                onPressed: widget._isWithinBounds(widget.currentDate)
                    ? () => _setDisplayed(widget.currentDate)
                    : null,
                child: Text(widget.labels.today),
              )
            ]),
          ]),
      };
    }
    return ColoredBox(
        color: theme.headerBackgroundColor ?? Colors.transparent,
        child:
            Padding(padding: const EdgeInsets.only(bottom: 4), child: header));
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
    return DecoratedBox(
      decoration: BoxDecoration(
          border: theme.showGridLines == true
              ? Border(bottom: BorderSide(color: theme.borderColor!))
              : null),
      child: Row(
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
      ),
    );
  }

  List<Widget> _buildDays(BuildContext context,
      MaterialLocalizations localizations, GeneralCalendarThemeData theme,
      {required DateTime anchor, bool multiMonth = false}) {
    final month = _delegate.getMonth(anchor.year, anchor.month);
    final week = _view == GeneralCalendarView.week;
    final offset = week
        ? _weekOffset(anchor, localizations)
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
                          (!widget.showAdjacentMonthDays || multiMonth) &&
                          (index < 0 || index >= length)) {
                        return _blankDay(theme, column);
                      }
                      final date = week
                          ? _tryAddDays(anchor, index)
                          : index >= 0 && index < length
                              ? _delegate.getDay(
                                  month.year, month.month, index + 1)
                              : _tryAddDays(month, index);
                      return date == null
                          ? _blankDay(theme, column)
                          : _buildDay(context, date, localizations, theme,
                              month: month, column: column);
                    },
                  ),
                ),
              ),
          ],
        ),
    ];
  }

  BoxBorder? _gridBorder(GeneralCalendarThemeData theme, int column) =>
      theme.showGridLines == true
          ? BorderDirectional(
              bottom: BorderSide(color: theme.borderColor!),
              end: column == 6
                  ? BorderSide.none
                  : BorderSide(color: theme.borderColor!),
            )
          : null;

  Widget _blankDay(GeneralCalendarThemeData theme, int column) => DecoratedBox(
        decoration: BoxDecoration(border: _gridBorder(theme, column)),
        child: const SizedBox.expand(),
      );

  Widget _buildYear(BuildContext context, MaterialLocalizations localizations,
      GeneralCalendarThemeData theme) {
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
                          style: TextButton.styleFrom(
                            foregroundColor: theme.foregroundColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    (theme.dayRadius ?? 4).clamp(0, 16))),
                          ),
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

  Widget _buildDay(BuildContext context, DateTime date,
      MaterialLocalizations localizations, GeneralCalendarThemeData theme,
      {required DateTime month, required int column}) {
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
      isOutsideMonth: !_delegate.isSameMonth(date, month),
      isWeekend: widget.weekendDays.contains(date.weekday),
      isRangeStart: start,
      isRangeEnd: end,
      isInRange: inRange,
    );
    final colors = Theme.of(context).colorScheme;
    final normalForeground = theme.foregroundColor ?? colors.onSurface;
    final todayIndicator =
        theme.todayIndicator ?? CalendarTodayIndicator.outline;
    final foreground = disabled
        ? normalForeground.withValues(alpha: 0.38)
        : selected
            ? theme.selectedDayForegroundColor ?? colors.onPrimary
            : attributes.foregroundColor ??
                (attributes.isHoliday
                    ? theme.holidayColor ?? colors.error
                    : details.isWeekend
                        ? theme.weekendColor ?? normalForeground
                        : details.isOutsideMonth
                            ? theme.mutedForegroundColor ?? normalForeground
                            : normalForeground);
    final background = selected
        ? theme.selectedDayColor ?? colors.primary
        : attributes.backgroundColor ??
            (attributes.isVacation
                ? theme.vacationColor ?? colors.tertiaryContainer
                : details.isToday &&
                        todayIndicator == CalendarTodayIndicator.fill
                    ? theme.todayColor?.withValues(alpha: 0.12)
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
        child: LayoutBuilder(builder: (context, constraints) {
          final inset = theme.dayInset ?? 2;
          final radius = BorderRadius.circular(theme.dayRadius ?? 12);
          final eventLabels = theme.showEventLabels == true;
          final visualSize = (constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth
                  : constraints.maxHeight) -
              inset * 2;
          final custom = widget.dayBuilder?.call(context, details);
          Widget visual = Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
              border: details.isToday &&
                      todayIndicator == CalendarTodayIndicator.outline
                  ? Border.all(color: theme.todayColor ?? colors.primary)
                  : null,
            ),
            child: Stack(fit: StackFit.expand, children: [
              if (custom != null)
                Center(child: custom)
              else if (eventLabels)
                _eventDayContent(
                    context, details, localizations, theme, foreground)
              else
                Center(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(localizations.formatDecimal(date.day),
                                style: (theme.dayTextStyle ??
                                        Theme.of(context).textTheme.bodyMedium!)
                                    .copyWith(
                                        color: foreground,
                                        fontWeight:
                                            selected ? FontWeight.w600 : null)),
                            if (attributes.tags.isNotEmpty)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                for (final tag in attributes.tags.take(3))
                                  Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: tag.color ?? foreground)),
                              ]),
                          ],
                        ))),
              if (details.isToday &&
                  !eventLabels &&
                  (todayIndicator == CalendarTodayIndicator.dot ||
                      todayIndicator == CalendarTodayIndicator.underline))
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Container(
                        width: todayIndicator == CalendarTodayIndicator.dot
                            ? 4
                            : 16,
                        height: todayIndicator == CalendarTodayIndicator.dot
                            ? 4
                            : 2,
                        decoration: BoxDecoration(
                            color: selected ? foreground : theme.todayColor,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    )),
            ]),
          );
          if (!eventLabels) {
            visual = Center(
                child: SizedBox(
                    width: visualSize.clamp(0, double.infinity),
                    height: visualSize.clamp(0, double.infinity),
                    child: visual));
          }
          return Ink(
            decoration: BoxDecoration(
              color: details.isWeekend ? theme.weekendBackgroundColor : null,
              border: _gridBorder(theme, column),
            ),
            child: Stack(fit: StackFit.expand, children: [
              if (inRange && !(start && end))
                PositionedDirectional(
                  start: start ? constraints.maxWidth / 2 : 0,
                  end: end ? constraints.maxWidth / 2 : 0,
                  top: inset,
                  bottom: inset,
                  child:
                      Ink(color: theme.rangeColor ?? colors.primaryContainer),
                ),
              visual,
              Positioned.fill(
                  child: InkWell(
                borderRadius: eventLabels ? BorderRadius.zero : radius,
                hoverColor: theme.hoverColor,
                focusColor: theme.focusColor,
                onTap: disabled || widget.readOnly ? null : () => _select(date),
              )),
            ]),
          );
        }),
      ),
    );
    final tooltip = attributes.tooltip ??
        (attributes.tags.isEmpty
            ? null
            : attributes.tags.map((tag) => tag.label).join(', '));
    if (tooltip != null) content = Tooltip(message: tooltip, child: content);
    return content;
  }

  Widget _eventDayContent(
      BuildContext context,
      CalendarDayDetails day,
      MaterialLocalizations localizations,
      GeneralCalendarThemeData theme,
      Color foreground) {
    return LayoutBuilder(builder: (context, constraints) {
      final textHeight = MediaQuery.textScalerOf(context).scale(11) * 1.3 + 4;
      final numberHeight = MediaQuery.textScalerOf(context)
                  .scale(theme.dayTextStyle?.fontSize ?? 14) *
              (theme.dayTextStyle?.height ?? 1.4) +
          4;
      final available = constraints.maxHeight - numberHeight - 12;
      final tags = day.attributes.tags;
      final capacity = (available / textHeight).floor().clamp(0, 3);
      // Reserve a line for the hidden count instead of silently dropping tags
      // when the cell can fit labels but cannot fit every event.
      final count = tags.length <= capacity && tags.length <= 2
          ? tags.length
          : (capacity - 1).clamp(0, 2);
      final todayColor =
          theme.todayColor ?? Theme.of(context).colorScheme.primary;
      final todayForeground =
          ThemeData.estimateBrightnessForColor(todayColor) == Brightness.dark
              ? Colors.white
              : Colors.black;
      return Padding(
        padding: const EdgeInsets.all(4),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
              height: numberHeight.clamp(0, constraints.maxHeight - 12),
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.topEnd,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: day.isToday
                        ? BoxDecoration(
                            color: todayColor,
                            borderRadius: BorderRadius.circular(20))
                        : null,
                    child: Text(localizations.formatDecimal(day.date.day),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.dayTextStyle?.copyWith(
                            color: day.isToday ? todayForeground : foreground)),
                  ))),
          const SizedBox(height: 4),
          for (final tag in tags.take(count))
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: (tag.color ?? todayColor).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(tag.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 11, color: foreground, height: 1.3)),
            ),
          if (tags.length > count && capacity > count)
            Text('+${localizations.formatDecimal(tags.length - count)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: foreground, height: 1.3)),
        ]),
      );
    });
  }
}
