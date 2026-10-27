# General Calendar example

A runnable Flutter playground for `general_calendar`, plus a complete local
appointment form. Web and Android runners are included; the widgets also work in
other native Flutter applications.

## Run

From this directory, with Flutter 3.32+ installed:

```sh
flutter pub get
flutter run -d chrome
```

For a connected Android device, use `flutter devices` to find its ID, then run
`flutter run -d <device-id>`. To build and install the release example instead:

```sh
flutter build apk --release
flutter install --release -d <device-id>
```

The Android app is named **General Calendar** and uses application ID
`dev.generalcalendar.general_calendar_example`. The example's release build uses
the local debug signing key for device testing.

The example imports `general_calendar` from `..` and uses `general_datetime` for
Persian, Hijri, and Hebrew arithmetic and English calendar labels. It also bundles
the `cupertino_icons` font for Flutter's Cupertino controls. When developing
against the neighboring `general_date` checkout, create this ignored file before
running `flutter pub get`:

```yaml
# example/pubspec_overrides.yaml
dependency_overrides:
  general_datetime:
    path: ../../general_date
  general_datetime_core:
    path: ../../general_date/packages/general_datetime_core
```

Local sibling dependencies are required until `general_datetime` 4.0.0 is
published to pub.dev. The example uses that release's Hebrew calendar APIs.
For another target, generate its runner with
`flutter create --platforms=windows .` (substitute your target), then run
`flutter run -d windows`.

## Try the playground

| Area | What it demonstrates |
| --- | --- |
| Calendar system | Gregorian, Persian, Hijri, Hebrew; explicit date conversion and one matching localization delegate |
| Selection | Single date, toggled multiple dates with a configurable limit, and inclusive ranges with pending end dates |
| Style | All 12 presets, a comparison gallery, dark mode, inherited theme and widget overrides |
| Calendar options | Starting month/week/year view, locale or explicit week start, Friday or Saturday/Sunday weekends, adjacent dates, two responsive month panels |
| Date rules | Disabled Fridays, an independent today-or-later predicate, read-only browsing, and optional disabled range interiors |
| Date content | Holidays, vacations, event tags, tooltips, semantics, metadata, and an optional custom availability cell |
| Selection details | Calendar runtime type, available places and sample price for the selected date |
| Dialogs | Date, inclusive range, time, and combined date-time confirmation/cancellation |
| Time input | Numeric input, dial, wheels, dropdown, appointment slots, 12/24-hour display and optional hidden unavailable slots |
| Appointment form | Inline combined picker, initial date-time, exact minimum date-time, per-date availability, nullable draft validation and confirmation |
| Diagnostics | The most recent eight selection, navigation, view and reset callbacks |
| Layout | Narrow-screen scrolling, adaptive month panels and an RTL layout preview |

Suggested walkthrough:

1. Select **multiple**, choose five dates, and toggle one off. Change the limit in
   **Calendar options** or press **Reset calendar** to start again.
2. Select **range**. A first tap shows “Choose end”; a second completes the range.
   Try spanning a Friday, then enable **Allow disabled days inside ranges**.
   Disabled endpoints remain unavailable.
3. Open **Calendar options**, enable custom day cells and purple theme overrides,
   and change the starting view. The calendar header also switches views without
   resetting selection. Try two month panels on a wide window.
4. Switch to Persian, Hijri, or Hebrew. The displayed fields and returned runtime
   types belong to the selected calendar. Compare styles, then return to the demo.
5. Open each dialog. Confirmation requires a valid selection; cancellation leaves
   the previous dialog result unchanged. Calendar dialogs share the active date
   rules and style. The time dialog shares the inline time rules.
6. In **Time pickers**, enter `12:30`, an off-interval minute such as `14:31`, or an
   incomplete hour. The nullable callback clears the valid result. Change views
   to compare the same rules across every input style.
7. Open **Appointment example**. It starts at the next available date at 14:30.
   Today is bounded below by 14:30; future dates use the full office schedule.
   Choose an available time and confirm the local demo appointment to inspect its
   calendar type and corresponding UTC instant.

These recurring rules are fictional: day 1 is a holiday, days 10–12 are vacation,
day 15 has a meeting, and multiples of 7 have a workshop. Places and USD prices
are sample metadata. Holidays, vacations and zero places do **not** disable dates.
The appointment form does not send or persist bookings.

The RTL switch previews layout with English labels. It does not translate the
calendar. For multilingual text, install matching localization adapters from
`general_date_format` and supply package-specific `GeneralCalendarLabels` and
`GeneralTimePickerLabels`; avoid competing calendar localizations in one scope.

## Source map

- [lib/main.dart](lib/main.dart): app configuration, calendar playground,
  dialogs, time inputs and callback log.
- [lib/demo_data.dart](lib/demo_data.dart): shared synchronous date attributes,
  time predicates, formatting and custom day content.
- [lib/appointment_example.dart](lib/appointment_example.dart): an application
  form using `GeneralDateTimePicker` and calendar-safe date/time composition.
- [lib/design_gallery.dart](lib/design_gallery.dart): all presets side by side.
- [lib/demo_dropdown.dart](lib/demo_dropdown.dart): labeled controls compatible
  with the package's Flutter minimum.
- [test/widget_test.dart](test/widget_test.dart): existing integration coverage.
- [test/playground_test.dart](test/playground_test.dart): selection policies,
  dialog cancellation, custom content and appointment validation.

## Integration notes

Keep date arithmetic in the selected `CalendarDelegate`: use `getMonth`,
`addDaysToDate`, and `dateOnly`. `CalendarDateTimeUtils.combine` joins a calendar
date with a `TimeOfDay` while preserving its type; reconstructing it with native
`DateTime(year, month, day)` would lose that calendar.

Initial values seed internal state. The playground deliberately changes the
calendar key when resetting, switching calendars/modes, or changing selection
rules. Style, layout, and read-only changes preserve selection. The appointment
form seeds `initialDateTime` once; it listens to `onSelectionChanged`, including
null for unavailable drafts, to enable or disable its confirmation action.

Attribute resolvers are synchronous. Fetch real availability outside these
callbacks, cache it in application state, and rebuild when it changes. A custom
`dayBuilder` supplies noninteractive cell content while the calendar retains
selection handling and accessibility semantics.

See the package [README](../README.md), [design guide](../docs/calendar-designs.md),
and [time picker guide](../docs/time-pickers.md) for the complete API context.

## Verify

```sh
flutter analyze
flutter test
flutter build web
```
