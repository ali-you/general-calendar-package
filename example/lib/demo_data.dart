import 'package:flutter/material.dart';
import 'package:general_calendar/general_calendar.dart';

/// Application-owned data shared by inline widgets and dialogs. These recurring
/// rules are illustrative, not an official holiday or availability service.
abstract final class DemoData {
  static const openingTime = TimeOfDay(hour: 9, minute: 0);
  static const closingTime = TimeOfDay(hour: 17, minute: 0);
  static const initialTime = TimeOfDay(hour: 14, minute: 30);

  static bool isOfficeTime(TimeOfDay time) => time.hour != 12;

  static bool isAppointmentTime(DateTime date, TimeOfDay time) =>
      isOfficeTime(time) && (date.day != 15 || time.hour >= 13);

  static CalendarDateAttributes attributes(DateTime date,
          {bool blockFridays = true}) =>
      CalendarDateAttributes(
        isDisabled: blockFridays && date.weekday == DateTime.friday,
        isHoliday: date.day == 1,
        isVacation: date.day >= 10 && date.day <= 12,
        tags: [
          if (date.day == 15)
            const CalendarTag(label: 'Team meeting', color: Colors.orange),
          if (date.day % 7 == 0)
            const CalendarTag(label: 'Workshop', color: Colors.blue),
        ],
        tooltip: blockFridays && date.weekday == DateTime.friday
            ? 'Closed on Fridays'
            : '${date.day % 5} places available',
        semanticLabel: '${date.day % 5} places available',
        metadata: {'availablePlaces': date.day % 5, 'price': 40 + date.day},
      );

  static String dateLabel(DateTime date) =>
      '${date.year}/${date.month}/${date.day}';

  static String timeLabel(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static String dateTimeLabel(DateTime date) =>
      '${dateLabel(date)} ${timeLabel(TimeOfDay.fromDateTime(date))}';

  /// Customize content only: the calendar keeps tap handling, selection fill,
  /// keyboard focus, tooltips, and semantics. The builder supplies foreground
  /// colors for its own text. A null result uses the default cell.
  static Widget? availabilityDay(BuildContext context, CalendarDayDetails day,
      {required GeneralCalendarThemeData theme}) {
    if (day.isOutsideMonth) return null;
    final localizations = MaterialLocalizations.of(context);
    final places = day.attributes.metadata['availablePlaces']! as int;
    final colors = Theme.of(context).colorScheme;
    final normal = theme.foregroundColor ?? colors.onSurface;
    final foreground = day.isDisabled
        ? normal.withValues(alpha: 0.38)
        : day.isSelected
            ? theme.selectedDayForegroundColor ?? colors.onPrimary
            : day.attributes.foregroundColor ??
                (day.attributes.isHoliday
                    ? theme.holidayColor ?? colors.error
                    : day.isWeekend
                        ? theme.weekendColor ?? normal
                        : normal);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(localizations.formatDecimal(day.date.day),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: foreground)),
          const SizedBox(height: 2),
          Text('$places left',
              style: TextStyle(fontSize: 10, color: foreground)),
        ],
      ),
    );
  }
}
