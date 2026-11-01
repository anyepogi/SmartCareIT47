import 'package:flutter/material.dart';

Future<bool> confirmSmartCareSignOut(BuildContext context) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
<<<<<<< HEAD
    builder: (context) {
      // Tablets (wider than 800px) get a wider dialog with larger text;
      // phones keep the default AlertDialog.
      final tablet = MediaQuery.sizeOf(context).width > 800;
      final buttonStyle = tablet
          ? TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            )
          : null;

      return AlertDialog(
        shape: tablet
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
            : null,
        titlePadding: tablet ? const EdgeInsets.fromLTRB(32, 32, 32, 0) : null,
        contentPadding: tablet
            ? const EdgeInsets.fromLTRB(32, 16, 32, 8)
            : null,
        actionsPadding: tablet
            ? const EdgeInsets.fromLTRB(24, 8, 24, 20)
            : null,
        title: Text(
          'Sign out of SmartCare?',
          style: tablet
              ? const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)
              : null,
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tablet ? 440 : 0),
          child: Text(
            'Are you sure you want to sign out of your account?',
            style: tablet ? const TextStyle(fontSize: 18, height: 1.4) : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: buttonStyle,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: buttonStyle,
            child: const Text('Sign Out'),
          ),
        ],
      );
    },
=======
    builder: (context) => AlertDialog(
      title: const Text('Sign out of SmartCare?'),
      content: const Text('Are you sure you want to sign out of your account?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign Out'),
        ),
      ],
    ),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
  );

  return shouldSignOut == true;
}
