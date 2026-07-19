import 'package:flutter/material.dart';
import 'package:maki_app/theme/app_tokens.dart';
import 'package:maki_app/utils/dates.dart';

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.firstDate,
    this.lastDate,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String? label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return InkWell(
      borderRadius: AppRadius.card,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          Dates.long(value, locale),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
