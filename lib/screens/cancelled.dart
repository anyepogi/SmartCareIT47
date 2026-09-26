import 'package:flutter/material.dart';

class AppointmentCancelledScreen extends StatelessWidget {
  const AppointmentCancelledScreen({
    super.key,
    this.dateTime = "Friday, June 15, 2026 at 2:00 PM",
    this.patientName = "Patient",
    this.appointmentId = "APT123456",
  });

  final String dateTime;
  final String patientName;
  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F2E4),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Cancellation Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEB),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.cancel,
                                color: Color(0xFFD32F2F),
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Appointment Cancelled!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Your appointment has been cancelled successfully. You can book a new appointment anytime.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF6E8D73),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Appointment Details Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE3EFE1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF000000,
                                  ).withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFFD32F2F),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Cancelled Appointment Details",
                                      style: TextStyle(
                                        color: Color(0xFFD32F2F),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _DetailRow(
                                  label: "Date & Time",
                                  value: dateTime,
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  label: "Patient Name",
                                  value: patientName,
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  label: "Appointment ID",
                                  value: appointmentId,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/dashboard');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Return",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF506D54),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1A3320),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
