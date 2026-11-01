import 'package:flutter/material.dart';

class AppointmentConfirmScreen extends StatelessWidget {
  const AppointmentConfirmScreen({
    super.key,
    this.dateTime = "Friday, June 15, 2026 at 2:00 PM",
    this.patientName = "Patient",
    this.appointmentId = "APT123456",
    this.location = "Sta. Rita",
    this.queueCode,
    this.isExistingView = false,
  });

  final String dateTime;
  final String patientName;
  final String appointmentId;
  final String location;

  /// The patient's place in line, like SO3. Null for old appointments
  /// booked before queue numbers.
  final String? queueCode;

  /// True when this screen is opened to view an appointment the patient
  /// already booked earlier, instead of right after a fresh booking.
  final bool isExistingView;

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final scaffold = Scaffold(
=======
    return Scaffold(
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
                          // Calendar check icon (matches Book Appointment action)
                          Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 200, 226, 186),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.event_available,
                              color: Color(0xFF147C28),
                              size: 50,
=======
                          // Checkmark Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F9E6),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Color(0xFF0DA94C),
                                size: 48,
                              ),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isExistingView
                                ? "You Have an Upcoming Appointment"
                                : "Appointment Confirmed!",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF0DA94C),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isExistingView
                                ? "You already have a booked appointment. Cancel it first if you'd like to book a different one."
                                : "Your appointment is confirmed. Patients are served in order of their queue number, so kindly arrive before the clinic opens.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                                      color: Color(0xFF006B2D),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Appointment Details",
                                      style: TextStyle(
                                        color: Color(0xFF006B2D),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (queueCode != null) ...[
                                  _DetailRow(
                                    label: "Queue Number",
                                    value: queueCode!,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                // Location
                                _DetailRow(label: "Location", value: location),
                                const SizedBox(height: 12),
                                // Date & Time
                                _DetailRow(
                                  label: "Date & Session",
                                  value: dateTime,
                                ),
                                const SizedBox(height: 12),
                                // Patient Name
                                _DetailRow(
                                  label: "Patient Name",
                                  value: patientName,
                                ),
                                const SizedBox(height: 12),
                                // Appointment ID
                                _DetailRow(
                                  label: "Reference No.",
                                  value: appointmentId,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Buttons
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/dashboard');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006B2D),
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
<<<<<<< HEAD

    // Tablets (wider than 800px) show all text 15% larger; phones are
    // unchanged.
    if (MediaQuery.sizeOf(context).width <= 800) return scaffold;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.15)),
      child: scaffold,
    );
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
