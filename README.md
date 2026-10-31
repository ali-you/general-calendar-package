# General Calendar

Flutter calendar widgets and date-picker dialogs using Flutter's own
`CalendarDelegate<DateTime>` interface. Gregorian works out of the box; pass a
matching delegate and dates for Persian, Hijri, Hebrew, Chinese, or your own calendar.

## Installation

Add the package to your Flutter application's `pubspec.yaml`:

```yaml
dependencies:
  general_calendar: ^1.1.0
```

Run `flutter pub get`, then import
`package:general_calendar/general_calendar.dart`.
For Persian, Hijri, Hebrew, or Chinese calendars, use matching calendar delegates and
date types as shown below. The five-calendar example uses
`general_datetime` 5.0.0 for Persian, Hijri, Hebrew, and Chinese chronology.
The Gregorian calendar needs no additional package.

Chinese calendars use `ChineseCalendarDelegate` and `ChineseDateTime` from
`general_datetime`, paired with `DefaultChineseCalendarMaterialLocalizations.delegate`
(or the translated companion formatter delegate). The example includes Chinese
calendar selection. Month navigation includes the repeated leap month.

## Features

- Inline month and week grids, plus a year overview that opens a chosen month.
- Animated month paging with horizontal touch, trackpad, and mouse dragging.
- Ten design-system-inspired presets, plus booking-range and event-grid layouts.
- Single-date, multiple-date, and inclusive date-range selection.
- Single-date and range dialogs with confirmation and cancellation.
- Time-only and combined date-time input, with numeric, dial, wheel, dropdown,
  and appointment-slot views, shared validation, and confirmation dialogs.
- Disabled dates, holidays, vacations, colored tags, tooltips, and custom metadata.
- Custom day builders and Material theme overrides.
- Locale-based week starts, configurable weekends, RTL layout, and day semantics.
- Keyboard focus and activation through Material controls.
- Delegate-based day/month arithmetic, including non-Gregorian leap months and
  finite calendar boundaries. No Gregorian reconstruction of custom dates.

Requires Flutter 3.32+ and Dart 3.4+. The runtime depends only on Flutter.
The chronology package is a development dependency for integration tests.

Choose a visual style with `design: GeneralCalendarDesign.shadcn` (or `material`,
`cupertino`, `fluent`, `carbon`, `antDesign`, `atlassian`, `spectrum`, `primer`,
`polaris`, `booking`, `eventGrid`). All use the same delegates and date rules.
See the [design catalog, sources, screenshots, and customization guide](docs/calendar-designs.md).
The example includes a style selector, dark mode, and a comparison gallery.
See the [time and date-time picker guide](docs/time-pickers.md) for the APIs,
availability rules, calendar-safe results, and screenshots.

## Inline calendar

```dart
import 'package:flutter/material.dart';
import 'package:general_calendar/general_calendar.dart';

GeneralCalendar(
  firstDate: DateTime(2024),
  lastDate: DateTime(2026, 12, 31),
  initialDate: DateTime(2024, 3, 20),
  onDateChanged: (date) => debugPrint('$date'),
  dateAttributes: (date) => CalendarDateAttributes(
    isDisabled: date.weekday == DateTime.friday,
    isHoliday: date.month == 3 && date.day == 21,
    isVacation: date.month == 7 && date.day <= 10,
    tags: date.day == 15
        ? const [CalendarTag(label: 'Meeting', color: Colors.orange)]
        : const [],
    tooltip: date.weekday == DateTime.friday ? 'Office closed' : null,
    metadata: {'availablePlaces': 8},
  ),
)
```

Dates are normalized through `calendarDelegate.dateOnly`. `firstDate` and
`lastDate` are required and inclusive. Initial selections must be in bounds and
selectable; invalid configurations throw `ArgumentError` in release builds too.
Holidays, vacations, and weekends do **not** automatically disable selection.
A date is selectable only when it is in bounds, `isDisabled` is false, and
`selectableDayPredicate` accepts it.

`initialDate`, `initialSelectedDates`, `initialDateRange`, `initialDisplayedDate`,
and `initialView` seed internal state, like Flutter's `CalendarDatePicker`.
Change the widget key to reset these values. Replacing the delegate or selection
mode also resets state. Changing bounds or rules removes stale selections
without firing user-interaction callbacks. Supply valid initial values on every
construction, including after rule changes.

Month view supports horizontal paging in the locale's text direction, including
two-month layouts. Header arrows animate the same viewport, and the calendar
height follows the visible months' row counts. Paging respects date bounds and
preserves the selection; `onDisplayedMonthChanged` reports month changes from
both gestures and header controls.

Set `enableSwipeNavigation: false` to keep navigation on the header controls.
Use `animationDuration: const Duration(milliseconds: 350)` to change the default
250 ms transition, or `Duration.zero` for immediate header navigation. Platform
reduced-motion settings automatically disable header animations. Week and year
views retain their existing header navigation.

## Calendars and localization

```dart
import 'package:general_datetime/general_datetime.dart';
import 'package:general_datetime/delegates.dart';

GeneralCalendar(
  firstDate: PersianDateTime(1400, 1, 1),
  lastDate: PersianDateTime(1410, 12, 29),
  initialDate: PersianDateTime(1403, 1, 1),
  calendarDelegate: const PersianCalendarDelegate(),
  onDateChanged: (date) {
    // date is a PersianDateTime, including in dateAttributes/dayBuilder.
  },
)
```

Install matching Material localizations in `MaterialApp.localizationsDelegates`
or a `Localizations.override` scope. The chronology package provides
`DefaultPersianCalendarMaterialLocalizations.delegate` (and Hebrew/Hijri
variants) through `general_datetime/default_localizations.dart` for English
calendar labels. For multilingual labels use the matching adapters from
`general_date_format`. An arithmetic delegate does not install translations.
Do not put competing calendar localizations in the same scope.

When switching calendars, convert all date inputs explicitly and install the
new matching localization scope. Use the regular arithmetic delegate, rather
than the chronology package's Flutter range-picker adapter: this package does
not probe unsupported range cells.

`GeneralCalendarLabels` translates the package-specific view menu and attribute
labels. Flutter supplies date names, numerals, navigation tooltips, and dialog
buttons. `firstDayOfWeek` uses Dart weekdays (Monday=1, Sunday=7); null follows
the locale. `weekendDays` uses the same numbering.

## Views and selection modes

```dart
GeneralCalendar(
  firstDate: DateTime(2024),
  lastDate: DateTime(2025, 12, 31),
  initialView: GeneralCalendarView.week, // month, week, year
  selectionMode: CalendarSelectionMode.multiple,
  initialSelectedDates: [DateTime(2024, 3, 20)],
  maxSelectedDates: 5,
  onDatesChanged: (dates) {}, // immutable, sorted, date-only snapshot
)
```

Use `initialDate` / `onDateChanged` for single selection,
`initialSelectedDates` / `onDatesChanged` for multiple selection, and
`initialDateRange` / `onDateRangeChanged` for ranges. Initial selection inputs
must match the selection mode. Multiple selection toggles a day on each tap.

`onSelectionChanged` works for every mode. In range mode it reports a pending
`rangeStart` after the first tap and a complete `range` after the second tap.
Reverse endpoints are sorted; equal endpoints produce a one-day range. Tapping
after a complete range starts a new range. `onDateRangeChanged` fires only for
complete ranges.

By default a range cannot contain a disabled day. Set
`allowDisabledDatesInRange: true` to permit disabled interior dates; endpoints
must still be selectable. Interior validation walks the dates synchronously,
so keep predicates inexpensive for long ranges. Attributes are also resolved
synchronously: load network data outside the resolver and rebuild when ready.

`readOnly` prevents selection while allowing navigation. `showAdjacentMonthDays`
includes neighboring days where the delegate supports them.
`onDisplayedMonthChanged` reports month navigation; `onViewChanged` reports view
changes. View selection is available through the header menu unless
`showViewSwitcher` is false. The year overview shows months in the displayed
year, including leap months, limited to the allowed date interval.

## Dialogs

```dart
final date = await showGeneralDatePicker(
  context: context,
  firstDate: DateTime(2024),
  lastDate: DateTime(2026, 12, 31),
  initialDate: DateTime(2024, 3, 20),
);

final range = await showGeneralDateRangePicker(
  context: context,
  firstDate: DateTime(2024),
  lastDate: DateTime(2026, 12, 31),
  dateAttributes: (date) => CalendarDateAttributes(
    isDisabled: date.weekday == DateTime.friday,
  ),
);
```

Both dialogs accept `calendarDelegate`, `dateAttributes`,
`selectableDayPredicate`, `dayBuilder`, `theme`, `labels`, and week configuration.
They return null on cancellation or dismissal. Confirmation is disabled until
a valid date or complete range is selected. Use `builder` for per-dialog theme
or calendar localization overrides, and `locale` to choose the dialog locale.
These are calendar-only dialogs; text-input mode and state restoration are
not implemented. They are familiar Material APIs, not drop-in replacements
for every parameter of Flutter's pickers.

## Rendering and theme

```dart
GeneralCalendarTheme(
  data: const GeneralCalendarThemeData(
    selectedDayColor: Colors.indigo,
    holidayColor: Colors.red,
    vacationColor: Color(0xFFE0F2F1),
    dayHeight: 56,
  ),
  child: GeneralCalendar(
    firstDate: DateTime(2024),
    lastDate: DateTime(2025, 12, 31),
    dayBuilder: (context, day) {
      // Includes date, attributes, enabled/selected/today/weekend state,
      // outside-month state, and range endpoints/interior.
      if (day.attributes.metadata['availablePlaces'] == 0) {
        return const Icon(Icons.event_busy);
      }
      return null; // Use default content.
    },
  ),
)
```

A widget-level `theme` layers over the inherited theme and the selected design.
Only explicitly supplied values override earlier layers.
Disabled and selected foreground colors take priority
over per-date foreground colors. Selection fill takes priority over per-date
backgrounds. Tag labels appear in semantics/tooltips; up to three colored dots
appear in the default cell. `semanticLabel` adds application-specific context.
Collections are shallow immutable snapshots; keep nested metadata immutable.

Builders customize cell content; the calendar retains interaction and semantics.
Use noninteractive builder content. Supply a finite width to inline calendars.
Increase `dayHeight` (minimum 48) for large text or richer custom day content.
Layout and text scaling should be checked in the consuming application's target
sizes. There is no drag selection or arrow-key day navigation yet; Material
controls support Tab focus and Enter/Space activation.

## Useful future attributes

The interface already includes weekends, tooltips, accessibility descriptions,
per-date colors, and arbitrary metadata. Useful next additions are:

| Attribute | Use |
| --- | --- |
| `disabledReason` | Explain unavailable dates consistently in UI and semantics |
| `events` / `eventCount` | Agenda previews, reminders, and density indicators |
| `availability` / `capacity` | Booking and staffing workflows |
| `price` / `currencyCode` | Per-day travel or reservation pricing |
| `isTentative` / `status` | Pending, confirmed, and cancelled schedules |
| `minRangeDays` / `maxRangeDays` | Stay-length rules on the selection policy |
| `secondaryDateLabel` | Dual-calendar labels on each day |

Use `metadata` and `dayBuilder` for application-specific data today. Keep
booking rules in selection policy rather than making holidays inherently blocked.

## Local development and verification

To develop and test against the neighboring chronology repository, create these
ignored `pubspec_overrides.yaml` files:

```yaml
# Repository root: pubspec_overrides.yaml
dependency_overrides:
  general_datetime:
    path: ../general_date
  general_datetime_core:
    path: ../general_date/packages/general_datetime_core
```

In `example/pubspec_overrides.yaml`, use `../../general_date` and
`../../general_date/packages/general_datetime_core` instead. These overrides are
optional for development against the local chronology checkout. Applications using
the package's Gregorian widgets depend only on Flutter.

```sh
flutter pub get
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test example/lib example/test
cd example
flutter test
```

The [comprehensive example](example/README.md) includes five calendars, all
selection modes and views, configurable date rules, custom day cells, all style
presets, four picker dialogs, five time inputs, and an inline appointment form.
It includes a web runner: run `flutter pub get` and `flutter run -d chrome` from
`example`. See its README for native runner setup, local dependency overrides,
and a guided walkthrough.

Verification uses Flutter 3.47.6 / Dart 3.13.5: package tests (115),
example tests (16), analysis, and formatting passed.
The tests cover calendar switching, Hebrew leap months, finite Hijri bounds,
disabled-date rules, range selection, dialogs, keyboard activation, RTL, and a
phone-size example. Minimum-SDK and device/browser execution were not verified.
