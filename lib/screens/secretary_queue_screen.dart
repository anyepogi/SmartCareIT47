import 'package:flutter/material.dart';
import '../state/app_session.dart';
import 'staff_queue_screen.dart';

/// The secretary's Queue tab. The screen itself is shared with the doctor
/// in [StaffQueueScreen].
class SecretaryQueueScreen extends StatelessWidget {
  const SecretaryQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffQueueScreen(role: UserRole.secretary);
  }
}
