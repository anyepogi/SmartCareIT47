import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'smartcare_date_picker.dart';
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a

const List<String> _monthNames = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

/// Parses a "yyyy-MM-dd" string (the format the backend's DATE column
/// uses) into a [DateTime], or null if it isn't in that shape.
DateTime? _parseIsoDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

String _isoDate(DateTime date) {
  return "${date.year.toString().padLeft(4, '0')}-"
      "${date.month.toString().padLeft(2, '0')}-"
      "${date.day.toString().padLeft(2, '0')}";
}

String _friendlyDate(DateTime date) {
  return "${_monthNames[date.month - 1]} ${date.day}, ${date.year}";
}

<<<<<<< HEAD
TextStyle _labelStyle(bool large) => large
    ? TextStyle(
        color: Colors.grey.shade700,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      )
    : const TextStyle(
        color: Color(0xFF999999),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );

TextStyle _valueStyle(bool large) => large
    ? const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      )
    : const TextStyle(
        color: Color(0xFF006B2D),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
/// A profile field styled like [ProfileGenderField]'s container, but for
/// picking a birth date via the native calendar instead of free typing.
/// The value passed in/out through [onChanged] is always "yyyy-MM-dd" (what
/// the backend's DATE column expects); the display is friendlier.
class ProfileDateField extends StatelessWidget {
  const ProfileDateField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isEditing,
    this.onChanged,
<<<<<<< HEAD
    this.large = false,
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isEditing;
  final ValueChanged<String>? onChanged;

<<<<<<< HEAD
  /// Tablet styling: roomier padding, darker labels and bigger values.
  final bool large;

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
  String get _displayText {
    final parsed = _parseIsoDate(value);
    if (parsed != null) return _friendlyDate(parsed);
    return value;
  }

  Future<void> _pickDate(BuildContext context) async {
    final initial = _parseIsoDate(value) ?? DateTime(2000);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
<<<<<<< HEAD
      builder: smartCareDatePickerBuilder,
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: label,
    );
    if (picked != null) {
      onChanged?.call(_isoDate(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
<<<<<<< HEAD
      padding: large
          ? const EdgeInsets.symmetric(vertical: 12, horizontal: 16)
          : const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
=======
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEditing ? const Color(0xFF006B2D) : const Color(0xFFE0E0E0),
          width: isEditing ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF006B2D), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: isEditing
                ? InkWell(
                    onTap: () => _pickDate(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
<<<<<<< HEAD
                        Text(label, style: _labelStyle(large)),
=======
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                value.isEmpty ? 'Select date' : _displayText,
<<<<<<< HEAD
                                style: TextStyle(
                                  color: const Color(0xFF006B2D),
                                  fontSize: large ? 16 : 13,
=======
                                style: const TextStyle(
                                  color: Color(0xFF006B2D),
                                  fontSize: 13,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_month,
                              color: Color(0xFF006B2D),
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< HEAD
                      Text(label, style: _labelStyle(large)),
                      const SizedBox(height: 2),
                      Text(
                        value.isEmpty ? 'Not provided' : _displayText,
                        style: _valueStyle(large),
=======
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value.isEmpty ? 'Not provided' : _displayText,
                        style: const TextStyle(
                          color: Color(0xFF006B2D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// A profile field for picking Gender from the backend's fixed set of
/// options (`enum('Male','Female','Other')`) instead of free typing.
class ProfileGenderField extends StatelessWidget {
  const ProfileGenderField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isEditing,
    this.onChanged,
<<<<<<< HEAD
    this.large = false,
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
  });

  static const List<String> options = ['Male', 'Female', 'Other'];

  final IconData icon;
  final String label;
  final String value;
  final bool isEditing;
  final ValueChanged<String>? onChanged;

<<<<<<< HEAD
  /// Tablet styling: roomier padding, darker labels and bigger values.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: large
          ? const EdgeInsets.symmetric(vertical: 12, horizontal: 16)
          : const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
=======
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEditing ? const Color(0xFF006B2D) : const Color(0xFFE0E0E0),
          width: isEditing ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF006B2D), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: isEditing
                ? DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      initialValue: options.contains(value) ? value : null,
                      isDense: true,
<<<<<<< HEAD
                      style: TextStyle(
                        color: const Color(0xFF006B2D),
                        fontSize: large ? 16 : 13,
=======
                      style: const TextStyle(
                        color: Color(0xFF006B2D),
                        fontSize: 13,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: label,
<<<<<<< HEAD
                        labelStyle: _labelStyle(large),
=======
                        labelStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      hint: const Text(
                        'Select gender',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 13,
                        ),
                      ),
                      items: options
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                      onChanged: (selected) {
                        if (selected != null) onChanged?.call(selected);
                      },
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< HEAD
                      Text(label, style: _labelStyle(large)),
                      const SizedBox(height: 2),
                      Text(
                        value.isEmpty ? 'Not provided' : value,
                        style: _valueStyle(large),
=======
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value.isEmpty ? 'Not provided' : value,
                        style: const TextStyle(
                          color: Color(0xFF006B2D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
