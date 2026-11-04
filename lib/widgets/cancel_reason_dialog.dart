import 'package:flutter/material.dart';

/* Asks staff to confirm cancelling [patientName]'s appointment and to
type why. Used by both the Now Serving screen and Appointment
Management, so cancelling looks and works the same in both places.
Returns the reason ("No reason provided." if left blank), or null if
they backed out. */
Future<String?> showCancelReasonDialog(
  BuildContext context, {
  required String patientName,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CancelReasonDialog(patientName: patientName),
  );
}

/* The dialog owns its text controller and disposes it in dispose(), which
runs only once the dialog has fully left the screen. Disposing it right
after showDialog returned crashed the app ("_dependents.isEmpty"),
because the text box is still on screen during the closing animation. */
class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog({required this.patientName});

  final String patientName;

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Cancel Appointment"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This will cancel ${widget.patientName}'s appointment and notify "
            "them. A cancelled appointment can no longer be changed.",
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Reason for cancellation",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Back"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC41E3A),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final text = _reasonController.text.trim();
            Navigator.pop(context, text.isEmpty ? 'No reason provided.' : text);
          },
          child: const Text("Cancel Appointment"),
        ),
      ],
    );
  }
}
