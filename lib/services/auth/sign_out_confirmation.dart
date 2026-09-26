import 'package:flutter/material.dart';

Future<bool> confirmSmartCareSignOut(BuildContext context) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
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
  );

  return shouldSignOut == true;
}
