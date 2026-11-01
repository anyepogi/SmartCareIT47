import 'package:flutter/material.dart';
import '../state/app_session.dart';
import 'staff_queue_screen.dart';

/// The doctor's Queue tab. The screen itself is shared with the secretary
/// in [StaffQueueScreen].
class DoctorQueueScreen extends StatelessWidget {
  const DoctorQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffQueueScreen(role: UserRole.doctor);
  }
}
