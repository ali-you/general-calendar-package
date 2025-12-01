# general_calendar

A flexible and customizable calendar and date-picker UI library for Flutter.  
Designed to work seamlessly with the `general_datetime` package and date formatting utilities.

## Features

- Customizable calendar widgets
- Date picker and date range picker
- Multiple calendar views (month, year, decade, etc.)
- Full theming support for colors, shapes, and typography
- Responsive layout for mobile, tablet, desktop, and web
- Extensible architecture for building custom pickers
- Supports any calendar system when used with `general_datetime`
- Composable UI components
- Lightweight and fast with no unnecessary dependencies

## Getting Started

### Installation

```yaml
dependencies:
  general_calendar: ^1.0.0
```

Run:

```sh
flutter pub get
```

## Basic Usage

### Simple Date Picker

```dart
final date = await showGeneralDatePicker(
  context: context,
  initialDate: DateTime.now(),
);
```

### Inline Calendar

```dart
GeneralCalendar(
  onDateSelected: (date) {
    print("Selected: $date");
  },
);
```

### Date Range Picker

```dart
final range = await showGeneralDateRangePicker(
  context: context,
  initialRange: DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(Duration(days: 7)),
  ),
);
```

## Customization

### Custom Theme

```dart
GeneralCalendarTheme(
  selectedDayColor: Colors.blue,
  todayColor: Colors.red,
  dayTextStyle: TextStyle(fontSize: 14),
  child: GeneralCalendar(),
);
```

### Custom Day Builder

```dart
GeneralCalendar(
  dayBuilder: (context, day) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: day.isToday ? Colors.orange : null,
        shape: BoxShape.circle,
      ),
      child: Text("${day.day}"),
    );
  },
);
```

## Architecture Overview

The `general_calendar` package is designed with a modular architecture:

- Core calendar engine powered by `general_datetime`
- Rendering layer for days, weeks, and months
- Picker implementations (dialog, popup, inline)
- Theming and customization system
- Overridable components for advanced use cases

## Package Compatibility

| Package            | Purpose                                       |
|--------------------|-----------------------------------------------|
| general_datetime   | Calendar logic, conversions, computations     |
| general_calendar   | Calendar UI widgets and pickers               |
| Formatter package  | Date formatting utilities                     |

## Roadmap

- Dark mode presets
- Multi-date selection
- Scrollable month and year selectors
- Jalali, Hijri, and Solar calendar UI examples
- Event calendar
- Animated transitions

## Example Project

```sh
cd example
flutter run
```

## License

MIT License.

## Contributions

Contributions, issues, and feature requests are welcome.
