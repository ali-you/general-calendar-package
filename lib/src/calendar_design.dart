import 'package:flutter/material.dart';

import 'calendar_theme.dart';

/// Original Flutter adaptations of documented calendar patterns.
///
/// These presets are not official implementations or complete design-system
/// ports. They share the same calendar engine, rules, builders, and semantics.
/// No external fonts, logos, images, or JavaScript components are bundled.
enum GeneralCalendarDesign {
  material(
      'Material 3', 'https://m3.material.io/components/date-pickers/overview'),
  cupertino('Cupertino',
      'https://developer.apple.com/design/human-interface-guidelines/pickers'),
  fluent('Fluent',
      'https://github.com/microsoft/fluentui/tree/master/packages/react-components/react-calendar-compat'),
  carbon('Carbon',
      'https://www.carbondesignsystem.com/building-blocks/core/components/date-picker/specifications'),
  antDesign('Ant Design', 'https://ant.design/components/date-picker/'),
  atlassian('Atlassian', 'https://atlassian.design/components/calendar/'),
  spectrum('Spectrum', 'https://react-spectrum.adobe.com/v3/Calendar.html'),
  primer('Primer',
      'https://primer.style/product/internal-components/date-picker/'),
  polaris('Polaris',
      'https://shopify.dev/docs/api/app-home/latest/web-components/forms/date-picker'),
  shadcn('shadcn/ui', 'https://ui.shadcn.com/docs/components/calendar'),
  booking('Booking range', 'https://github.com/react-dates/react-dates'),
  eventGrid('Event grid', 'https://fullcalendar.io/docs/month-view');

  const GeneralCalendarDesign(this.label, this.referenceUrl);

  final String label;
  final String referenceUrl;

  bool get isDesignSystem => index < 10;

  /// Booking uses two consecutive month panels when at least 760 px is
  /// available. All other presets default to one. Widgets can override this.
  int get preferredVisibleMonths => this == booking ? 2 : 1;

  /// Resolves semantic colors for the ambient brightness. Typography inherits
  /// the application's font family instead of downloading proprietary fonts.
  GeneralCalendarThemeData resolve(ThemeData theme) {
    final dark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final surface = dark ? const Color(0xFF191C20) : Colors.white;
    final ink = dark ? const Color(0xFFF1F3F5) : const Color(0xFF20242A);
    final muted = dark ? const Color(0xFFADB5BD) : const Color(0xFF626B76);
    final border = dark ? const Color(0xFF444B55) : const Color(0xFFD9DEE5);
    GeneralCalendarThemeData palette({
      required Color accent,
      Color? selected,
      Color? onSelected,
      double radius = 8,
      double dayRadius = 4,
      double inset = 4,
      double dayHeight = 48,
      double padding = 12,
      CalendarHeaderLayout header = CalendarHeaderLayout.leading,
      CalendarTodayIndicator today = CalendarTodayIndicator.outline,
      CalendarNavigationStyle navigation = CalendarNavigationStyle.plain,
      bool bordered = true,
      bool divider = false,
      bool grid = false,
      bool events = false,
      Color? background,
      Color? headerBackground,
      double elevation = 0,
      double titleSize = 14,
      FontWeight titleWeight = FontWeight.w600,
    }) =>
        GeneralCalendarThemeData(
          selectedDayColor: selected ?? accent,
          selectedDayForegroundColor: onSelected ?? Colors.white,
          todayColor: accent,
          rangeColor: accent.withValues(alpha: dark ? 0.24 : 0.12),
          surfaceColor: background ?? surface,
          foregroundColor: ink,
          mutedForegroundColor: muted,
          borderColor: border,
          hoverColor: accent.withValues(alpha: 0.09),
          focusColor: accent.withValues(alpha: 0.28),
          surfaceRadius: radius,
          dayRadius: dayRadius,
          dayInset: inset,
          dayHeight: dayHeight,
          contentPadding: EdgeInsets.all(padding),
          headerLayout: header,
          todayIndicator: today,
          navigationStyle: navigation,
          showBorder: bordered,
          showHeaderDivider: divider,
          showGridLines: grid,
          showEventLabels: events,
          headerBackgroundColor: headerBackground,
          elevation: elevation,
          headerTextStyle: theme.textTheme.titleSmall?.copyWith(
            fontSize: titleSize,
            fontWeight: titleWeight,
            color: ink,
          ),
          dayTextStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
          weekdayTextStyle: theme.textTheme.labelSmall?.copyWith(
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        );
    return switch (this) {
      material => palette(
          accent: colors.primary,
          selected: colors.primary,
          onSelected: colors.onPrimary,
          radius: 28,
          dayRadius: 100,
          padding: 12,
          bordered: false,
          titleSize: 16,
          background: colors.surfaceContainerHigh,
        ),
      cupertino => palette(
          accent: dark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
          radius: 14,
          dayRadius: 100,
          inset: 5,
          padding: 12,
          titleSize: 17,
          titleWeight: FontWeight.w600,
          bordered: false,
        ),
      fluent => palette(
          accent: dark ? const Color(0xFF479EF5) : const Color(0xFF0F6CBD),
          selected: dark ? const Color(0xFF0E4775) : const Color(0xFFCFE4FA),
          onSelected: ink,
          radius: 4,
          dayRadius: 4,
          inset: 6,
          today: CalendarTodayIndicator.underline,
          elevation: 2,
        ),
      carbon => palette(
          accent: dark ? const Color(0xFF78A9FF) : const Color(0xFF0F62FE),
          selected: const Color(0xFF0F62FE),
          radius: 0,
          dayRadius: 0,
          inset: 0,
          padding: 4,
          header: CalendarHeaderLayout.split,
          today: CalendarTodayIndicator.dot,
          elevation: 2,
          background: dark ? const Color(0xFF262626) : Colors.white,
        ),
      antDesign => palette(
          accent: dark ? const Color(0xFF4096FF) : const Color(0xFF1677FF),
          selected: const Color(0xFF1677FF),
          radius: 8,
          dayRadius: 4,
          inset: 6,
          header: CalendarHeaderLayout.split,
          divider: true,
          titleWeight: FontWeight.w600,
        ),
      atlassian => palette(
          accent: dark ? const Color(0xFF85B8FF) : const Color(0xFF0C66E4),
          selected: dark ? const Color(0xFF454F59) : const Color(0xFFDCDFE4),
          onSelected: ink,
          radius: 3,
          dayRadius: 3,
          inset: 3,
          header: CalendarHeaderLayout.split,
          today: CalendarTodayIndicator.underline,
          bordered: false,
        ),
      spectrum => palette(
          accent: dark ? const Color(0xFF6CA8FF) : const Color(0xFF1473E6),
          selected: const Color(0xFF1473E6),
          radius: 4,
          dayRadius: 100,
          inset: 5,
          header: CalendarHeaderLayout.split,
          navigation: CalendarNavigationStyle.outlined,
          titleSize: 16,
          bordered: false,
        ),
      primer => palette(
          accent: dark ? const Color(0xFF4493F8) : const Color(0xFF0969DA),
          selected: const Color(0xFF0969DA),
          radius: 6,
          dayRadius: 6,
          inset: 5,
          header: CalendarHeaderLayout.centered,
          navigation: CalendarNavigationStyle.outlined,
          divider: true,
          headerBackground:
              dark ? const Color(0xFF212830) : const Color(0xFFF6F8FA),
        ),
      polaris => palette(
          accent: dark ? const Color(0xFF9BE5C1) : const Color(0xFF303030),
          selected: dark ? const Color(0xFFE3E3E3) : const Color(0xFF303030),
          onSelected: dark ? const Color(0xFF202020) : Colors.white,
          radius: 12,
          dayRadius: 8,
          inset: 4,
          titleWeight: FontWeight.w600,
          header: CalendarHeaderLayout.centered,
          navigation: CalendarNavigationStyle.filled,
        ),
      shadcn => palette(
          accent: dark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B),
          selected: dark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B),
          onSelected: dark ? const Color(0xFF18181B) : Colors.white,
          radius: 10,
          dayRadius: 6,
          inset: 5,
          header: CalendarHeaderLayout.split,
          navigation: CalendarNavigationStyle.outlined,
          today: CalendarTodayIndicator.fill,
        ),
      booking => palette(
          accent: dark ? const Color(0xFF70D5CE) : const Color(0xFF007A73),
          selected: const Color(0xFF007A73),
          radius: 12,
          dayRadius: 100,
          inset: 3,
          header: CalendarHeaderLayout.split,
          navigation: CalendarNavigationStyle.outlined,
          titleSize: 16,
          today: CalendarTodayIndicator.underline,
        ),
      eventGrid => palette(
          accent: dark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
          selected: dark ? const Color(0xFF16477D) : const Color(0xFFE8F0FE),
          onSelected: ink,
          radius: 8,
          dayRadius: 0,
          inset: 0,
          padding: 0,
          dayHeight: 112,
          titleSize: 20,
          header: CalendarHeaderLayout.stacked,
          today: CalendarTodayIndicator.fill,
          navigation: CalendarNavigationStyle.outlined,
          divider: true,
          grid: true,
          events: true,
        ),
    };
  }
}
