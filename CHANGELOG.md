## 1.1.0

* Align two-month headings with their grids, retain hidden-event counts in
  compact cells, and revalidate date/range availability before confirmation.

* Add animated horizontal month paging for touch, trackpad, and mouse dragging,
  with RTL navigation, adaptive heights, two-month layouts, date bounds, and
  reduced-motion support. Expose swipe and transition-duration options.

* Verify Chinese leap-month booking ranges in LTR/RTL, disabled range interiors,
  keyboard semantics, wall-time combination, and combined picker output.
* Add Chinese calendar example selection and integration coverage for leap-month
  navigation, year views, date selection and finite endpoints.
* Use `general_datetime ^5.0.0` in development and the example for the published
  Chinese chronology APIs.

## 1.0.0

* First stable release of the delegate-driven calendar and picker APIs.
* Document installation, calendar integration, selection policies, visual presets,
  time validation, and the runnable example.

* Add inline time-only and combined date-time pickers plus confirmation dialogs.
* Add numeric, dial, wheel, dropdown, and appointment-slot time input with
  shared inclusive bounds, minute increments, availability, 12/24-hour display,
  read-only behavior, and invalid-draft confirmation handling.
* Preserve calendar types when combining dates and wall times; add date-specific
  availability, exact date-time bounds, responsive layouts, and actual previews.

* Add ten design-system-inspired calendar presets and booking/event-grid layouts.
* Add light/dark design tokens, connected RTL-aware range fills, responsive
  two-month panels, event tag labels, dialog presets, and inherited theme capture.
* Add a preset comparison gallery, reference catalog, and Flutter-rendered previews.

* Replace the starter with delegate-driven month, week, and year calendar views.
* Add single, multiple, and inclusive range selection with shared date rules.
* Add date/range dialogs, disabled dates, holidays, vacations, tags, metadata,
  custom day content, theming, locale week starts, RTL, and accessible labels.
* Add Gregorian/Persian/Hijri/Hebrew integration tests and a four-calendar example.
