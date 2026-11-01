import 'package:flutter/material.dart';

import '../data/location_schedule.dart';
import '../services/appointment/appointment_service.dart';
<<<<<<< HEAD
import 'smartcare_date_picker.dart';
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a

/* Opens the secretary's "Add Walk-in" form: last name, first name, middle
name (optional), contact number, Gmail/email (optional), clinic, and
date. Saving records the walk-in in the
appointments table with the next queue number for that clinic and date,
shared with online bookings (so it shows as SW4, GW1, etc.). Returns the
booking, or null if the secretary closed the form without saving. */
Future<BookingResult?> showWalkInDialog(BuildContext context) {
  return showDialog<BookingResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _WalkInDialog(),
  );
}

class _WalkInDialog extends StatefulWidget {
  const _WalkInDialog();

  @override
  State<_WalkInDialog> createState() => _WalkInDialogState();
}

class _WalkInDialogState extends State<_WalkInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _contactNumber = TextEditingController();
  final _email = TextEditingController();
  String _location = clinicLocations.first;
  DateTime? _date;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = _nextBookableDate(_location);
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _middleName.dispose();
    _contactNumber.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Whether [day] is a clinic day for [location] whose session hasn't
  /// ended yet (walk-ins are usually recorded for today).
  bool _isBookable(String location, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day.isBefore(today)) return false;
    if (!isDateValidForLocation(location, day)) return false;
    return !(day == today && isSessionOver(location, day));
  }

  /// Today if it can still be booked at [location], otherwise the next
  /// clinic day there.
  DateTime? _nextBookableDate(String location) {
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 60; i++) {
      if (_isBookable(location, day)) return day;
      day = day.add(const Duration(days: 1));
    }
    return null;
  }

  String _dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _dateLabel(DateTime d) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[d.month - 1]} ${d.day}, ${d.year}";
  }

  Future<void> _pickDate() async {
    final initial = _date ?? _nextBookableDate(_location);
    if (initial == null) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
<<<<<<< HEAD
      builder: smartCareDatePickerBuilder,
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month + 3, now.day),
      helpText: "Walk-in date",
      selectableDayPredicate: (day) => _isBookable(_location, day),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final date = _date;
    if (date == null) {
      setState(() => _error = "Please choose a date.");
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final booking = await AppointmentService.bookWalkIn(
        lastName: _lastName.text.trim(),
        firstName: _firstName.text.trim(),
        middleName: _middleName.text.trim(),
        contactNumber: _contactNumber.text.trim(),
        email: _email.text.trim(),
        location: _location,
        date: _dateKey(date),
      );
      if (!mounted) return;
      Navigator.pop(context, booking);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? "Required" : null;

  /// Same rule as book_walkin.php: 7–15 digits, optionally starting with
  /// "+", ignoring spaces, dashes, and brackets.
  String? _validateContact(String? value) {
    final cleaned = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.isEmpty) return "Required";
    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned)) {
      return "Enter a valid number (e.g. 09171234567)";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return null; // optional
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return "Enter a valid email, or leave it blank";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // Tablets (wider than 800px) get a wider dialog with all its text a
    // little larger; phones are unchanged.
    final tablet = MediaQuery.sizeOf(context).width > 800;
    final dialog = AlertDialog(
      title: const Text("Add Walk-in"),
      content: SizedBox(
        width: tablet ? 560 : 420,
=======
    return AlertDialog(
      title: const Text("Add Walk-in"),
      content: SizedBox(
        width: 420,
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "Last Name"),
                  validator: _required,
                ),
                TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "First Name"),
                  validator: _required,
                ),
                TextFormField(
                  controller: _middleName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Middle Name (optional)",
                  ),
                ),
                TextFormField(
                  controller: _contactNumber,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Contact Number",
                    hintText: "09171234567",
                  ),
                  validator: _validateContact,
                ),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Gmail / Email (optional)",
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _location,
                  decoration: const InputDecoration(labelText: "Location"),
                  items: clinicLocations
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _location = value;
                      // Keep the date only if it's still a clinic day there.
                      if (_date == null || !_isBookable(value, _date!)) {
                        _date = _nextBookableDate(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Date",
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      _date == null
                          ? "No open clinic day found"
                          : "${_dateLabel(_date!)} "
                                "(${sessionTimeLabel(_location) ?? ''})",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "The walk-in gets the next queue number for this clinic "
                  "and date (for example SW4).",
                  style: TextStyle(fontSize: 12, color: Color(0xFF506D54)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16751F),
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Save Walk-in"),
        ),
      ],
    );
<<<<<<< HEAD

    if (!tablet) return dialog;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.15)),
      child: dialog,
    );
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
  }
}
