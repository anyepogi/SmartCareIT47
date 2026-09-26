import 'package:flutter/material.dart';

const List<String> _monthNames = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
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
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isEditing;
  final ValueChanged<String>? onChanged;

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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                value.isEmpty ? 'Select date' : _displayText,
                                style: const TextStyle(
                                  color: Color(0xFF006B2D),
                                  fontSize: 13,
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
  });

  static const List<String> options = ['Male', 'Female', 'Other'];

  final IconData icon;
  final String label;
  final String value;
  final bool isEditing;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      style: const TextStyle(
                        color: Color(0xFF006B2D),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: label,
                        labelStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
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
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
