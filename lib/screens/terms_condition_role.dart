import 'package:flutter/material.dart';

import '../state/app_session.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_bottom_nav.dart' show smartCareGoTo;

class TermsConditionsRoleScreen extends StatelessWidget {
  const TermsConditionsRoleScreen({super.key});

  void _goBackToMenu(BuildContext context) {
    final menuRoute = SmartCareSession.currentRole == UserRole.patient
        ? '/menu'
        : '/menu-doctor-nurse';
    smartCareGoTo(context, menuRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4E8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => _goBackToMenu(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: const Color(0xFF1C5D22),
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: Color(0xFFEAF4E8)),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TermsTitle("SmartCare Terms and Conditions"),
                            SizedBox(height: 14),
                            _TermsBody(
                              "Welcome to SmartCare. By accessing or using the SmartCare application, you agree to comply with and be bound by the following Terms and Conditions. Please read them carefully before using the application.",
                            ),
                            SizedBox(height: 18),
                            _TermsSection(
                              "1. Acceptance of Terms",
                              "By creating an account or using SmartCare, you acknowledge that you have read, understood, and agreed to these Terms and Conditions.\n\nIf you do not agree with any part of these terms, you must discontinue use of the application.",
                            ),
                            _TermsSection(
                              "2. Purpose of SmartCare",
                              "SmartCare is designed to:\n- Manage healthcare scheduling and appointments\n- Provide queue monitoring and notifications\n- Support geofencing and location-based services\n- Improve communication between patients and healthcare providers\n\nThe application is intended for lawful healthcare-related use only.",
                            ),
                            _TermsSection(
                              "3. User Accounts",
                              "Users are responsible for maintaining the confidentiality of their account information, including usernames and passwords.\n\nUsers agree to:\n- Provide accurate and updated information\n- Protect account credentials from unauthorized access\n- Notify administrators of suspicious account activity\n\nSmartCare is not responsible for losses caused by unauthorized use of user accounts.",
                            ),
                            _TermsSection(
                              "4. Location Services and Geofencing",
                              "SmartCare may request access to your device location to support geofencing and appointment monitoring features.\n\nBy using the application, you consent to the collection and use of location data for:\n- Tracking doctor arrival within designated areas\n- Sending location-based notifications\n- Improving appointment coordination\n\nDisabling location services may limit some app functionalities.",
                            ),
                            _TermsSection(
                              "5. User Responsibilities",
                              "Users must use SmartCare responsibly and agree not to:\n- Provide false information\n- Attempt unauthorized access to the system\n- Disrupt system operations\n- Share harmful software or malicious content\n- Misuse notifications or healthcare services\n\nViolation of these rules may result in account suspension or termination.",
                            ),
                            _TermsSection(
                              "6. Privacy and Data Protection",
                              "SmartCare values user privacy and applies reasonable security measures to protect user information.\n\nCollected data may include:\n- Personal information\n- Appointment records\n- Device and system information\n- Location data when enabled\n\nSmartCare does not sell user information to third parties.\nFor more information, please refer to the SmartCare Privacy Policy.",
                            ),
                            _TermsSection(
                              "7. Notifications and Alerts",
                              "The application may send:\n- Appointment reminders\n- Queue updates\n- Doctor arrival notifications\n- System announcements\n\nUsers are responsible for ensuring their devices can receive notifications properly.",
                            ),
                            _TermsSection(
                              "8. System Availability",
                              "SmartCare aims to provide continuous and reliable service. However, the application may experience interruptions due to:\n- System maintenance\n- Internet connection issues\n- Technical failures\n- Software updates\n\nSmartCare does not guarantee uninterrupted availability at all times.",
                            ),
                            _TermsSection(
                              "9. Limitation of Liability",
                              "The SmartCare development team shall not be held liable for:\n- Delayed or failed notifications\n- Incorrect user-provided information\n- Device compatibility issues\n- Service interruptions caused by external factors\n- Losses resulting from unauthorized account access\n\nUsers accept the risks associated with internet-based services.",
                            ),
                            _TermsSection(
                              "10. Intellectual Property",
                              "All SmartCare content, logos, system designs, and features are protected by applicable intellectual property laws.\n\nUsers may not copy, distribute, modify, or reproduce any part of the application without permission.",
                            ),
                            _TermsSection(
                              "11. Account Suspension and Termination",
                              "SmartCare reserves the right to suspend or terminate accounts that:\n- Violate these Terms and Conditions\n- Engage in suspicious or harmful activities\n- Misuse system functionalities\n\nTerminated users may lose access to their accounts and stored information.",
                            ),
                            _TermsSection(
                              "12. Changes to Terms and Conditions",
                              "SmartCare may update these Terms and Conditions at any time to improve services, comply with legal requirements, or enhance security.\n\nUsers will be notified of significant updates through the application.",
                            ),
                            _TermsSection(
                              "13. Governing Law",
                              "These Terms and Conditions shall be governed by the laws of the Republic of the Philippines.",
                            ),
                            _TermsSection(
                              "14. Contact Information",
                              "For concerns, questions, or support regarding SmartCare, users may contact the SmartCare support team through the application.",
                            ),
                            _TermsSection(
                              "Consent",
                              "By using SmartCare, you confirm that you understand and agree to these Terms and Conditions.",
                              hasBottomSpacing: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsTitle extends StatelessWidget {
  const _TermsTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1B5E20),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection(this.title, this.body, {this.hasBottomSpacing = true});

  final String title;
  final String body;
  final bool hasBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: hasBottomSpacing ? 18 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          _TermsBody(body),
        ],
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        height: 1.35,
        color: Color(0xFF315B34),
      ),
    );
  }
}
