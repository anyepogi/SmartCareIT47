import 'package:flutter/material.dart';

/// How much bigger the date picker gets on tablets. Flutter sizes the
/// DatePickerDialog from the text scale, so this grows the whole dialog
/// (about 556x388 in landscape, 403x636 in portrait) along with its text.
const double _tabletScale = 1.12;

const Color _green = Color(0xFF006D38);

/// Pass as `builder:` to every `showDatePicker` call. On tablets (wider than
/// 800px) it enlarges the dialog and applies SmartCare's green styling;
/// phones get the default picker unchanged.
Widget smartCareDatePickerBuilder(BuildContext context, Widget? child) {
  if (child == null) return const SizedBox.shrink();
  if (MediaQuery.sizeOf(context).width <= 800) return child;

  final base = Theme.of(context);
  final selected = WidgetStateProperty.resolveWith<Color?>(
    (states) => states.contains(WidgetState.selected) ? _green : null,
  );
  final onSelected = WidgetStateProperty.resolveWith<Color?>(
    (states) => states.contains(WidgetState.selected) ? Colors.white : null,
  );
  // Font sizes below are before the 1.12 scale, e.g. 28 shows as ~31.
  final actionStyle = TextButton.styleFrom(
    foregroundColor: _green,
    textStyle: const TextStyle(fontSize: 14.3, fontWeight: FontWeight.bold),
  );

  return MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(_tabletScale)),
    child: Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: _green,
          onPrimary: Colors.white,
        ),
        // The "October 2026" month/year toggle uses titleSmall.
        textTheme: base.textTheme.copyWith(
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: const Color(0xFFF4F8F3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          headerHeadlineStyle: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headerHelpStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          weekdayStyle: const TextStyle(
            fontSize: 14.3,
            fontWeight: FontWeight.bold,
            color: _green,
          ),
          dayStyle: const TextStyle(fontSize: 14.8),
          yearStyle: const TextStyle(fontSize: 14.8),
          dayBackgroundColor: selected,
          dayForegroundColor: onSelected,
          yearBackgroundColor: selected,
          yearForegroundColor: onSelected,
          todayBorder: const BorderSide(color: _green),
          cancelButtonStyle: actionStyle,
          confirmButtonStyle: actionStyle,
        ),
      ),
      child: child,
    ),
  );
}
