import 'package:flutter/material.dart';
import 'package:general_calendar/general_calendar.dart';

/// All styles keep the selected calendar's arithmetic and date attributes.
class CalendarDesignGallery extends StatelessWidget {
  const CalendarDesignGallery({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.currentDate,
    required this.calendarDelegate,
    required this.dateAttributes,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime currentDate;
  final CalendarDelegate<DateTime> calendarDelegate;
  final CalendarDateAttributesBuilder dateAttributes;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('12 calendar styles')),
        body: LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1160
              ? 3
              : constraints.maxWidth >= 760
                  ? 2
                  : 1;
          final width =
              (constraints.maxWidth - 32 - (columns - 1) * 24) / columns;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(spacing: 24, runSpacing: 24, children: [
              for (final design in GeneralCalendarDesign.values)
                SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(design.label,
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        GeneralCalendar(
                          design: design,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          currentDate: currentDate,
                          initialDisplayedDate: currentDate,
                          calendarDelegate: calendarDelegate,
                          dateAttributes: dateAttributes,
                        ),
                      ],
                    )),
            ]),
          );
        }),
      );
}
