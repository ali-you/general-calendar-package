import 'package:flutter/material.dart';

/// A labeled, controlled dropdown using APIs available in Flutter 3.32.
class DemoDropdown<T> extends StatelessWidget {
  const DemoDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            isDense: true,
          ),
        ),
      );
}
