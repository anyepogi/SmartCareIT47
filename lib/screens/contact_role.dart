import 'package:flutter/material.dart';

import '../services/contact/contact_service.dart';
import '../state/app_session.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_bottom_nav.dart' show smartCareGoTo;

class ContactRoleScreen extends StatefulWidget {
  const ContactRoleScreen({super.key});

  @override
  State<ContactRoleScreen> createState() => _ContactRoleScreenState();
}

class _ContactRoleScreenState extends State<ContactRoleScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _concernController = TextEditingController();
  int _concernLength = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _concernController.dispose();
    super.dispose();
  }

  Future<void> _submitContactForm() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final concern = _concernController.text.trim();

    if (name.isEmpty || email.isEmpty || concern.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ContactService.sendMessage(
        name: name,
        email: email,
        concern: concern,
        actorUserId: SmartCareSession.currentUserId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent! We\'ll get back to you soon.'),
        ),
      );
      _nameController.clear();
      _emailController.clear();
      _concernController.clear();
      setState(() => _concernLength = 0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goBackToMenu() {
    final menuRoute = SmartCareSession.currentRole == UserRole.patient
        ? '/menu'
        : '/menu-doctor-nurse';
    smartCareGoTo(context, menuRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: _goBackToMenu,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1A3320),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: const [
                        Text(
                          'Contact Us',
                          style: TextStyle(
                            color: Color(0xFF006738),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'We\'re here to help! Reach out to us\nfor any questions or concerns.',
                          style: TextStyle(
                            color: Color(0xFF6E8D73),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // First Container: Form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF146F1C),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0A000000),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Name',
                            style: TextStyle(
                              color: Color(0xFF1A3320),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your name...',
                              hintStyle: const TextStyle(
                                color: Color(0xFFA8BDA5),
                              ),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Color(0xFF146F1B),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3EFE1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3EFE1),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Email',
                            style: TextStyle(
                              color: Color(0xFF1A3320),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Enter your email...',
                              hintStyle: const TextStyle(
                                color: Color(0xFFA8BDA5),
                              ),
                              prefixIcon: const Icon(
                                Icons.mail,
                                color: Color(0xFF146F1B),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3EFE1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3EFE1),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your concern',
                            style: TextStyle(
                              color: Color(0xFF1A3320),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _concernController,
                            maxLines: 5,
                            maxLength: 500,
                            onChanged: (value) {
                              setState(() {
                                _concernLength = value.length;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter your concern...',
                              hintStyle: const TextStyle(
                                color: Color(0xFFA8BDA5),
                              ),
                              prefixIcon: const Icon(
                                Icons.edit,
                                color: Color(0xFF146F1B),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3EFE1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3EFE1),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              counterText: '',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$_concernLength/500',
                              style: const TextStyle(
                                color: Color(0xFF9CB0A0),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : _submitContactForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF146F1B),
                                disabledBackgroundColor: const Color(
                                  0xFF146F1B,
                                ).withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                                shadowColor: const Color(
                                  0xFF146F1B,
                                ).withValues(alpha: 0.3),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.send,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Send Message',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 24),
                  // Second Container: Contact Details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF146F1C),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0A000000),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Details',
                            style: TextStyle(
                              color: Color(0xFF1A3320),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Addresses
                          _ContactDetailRow(
                            icon: Icons.location_on,
                            title: 'Sta. Rita',
                            value:
                                '100 C Mariano, San Vicente, Sta. Rita, Pampanga (AQM Pharmacy)',
                          ),
                          const SizedBox(height: 16),
                          _ContactDetailRow(
                            icon: Icons.location_on,
                            title: 'Guagua',
                            value:
                                'Annex 1 Room 102, RMC Medical Arts Building, San Roque, Guagua, Pampanga',
                          ),
                          const SizedBox(height: 16),
                          _ContactDetailRow(
                            icon: Icons.location_on,
                            title: 'Lubao',
                            value:
                                'J.P. Rizal St., Sta. Cruz, Lubao, Pampanga (Diagnostic Center Laboratory)',
                          ),
                          const SizedBox(height: 16),
                          // Phone
                          _ContactDetailRow(
                            icon: Icons.phone,
                            title: 'Contact No.',
                            value: 'Globe: 09176294108\nSun: 09424407691',
                          ),
                          const SizedBox(height: 16),
                          // Email
                          _ContactDetailRow(
                            icon: Icons.mail,
                            title: 'Email',
                            value: 'smartcare.support@gmail.com',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Privacy notice
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECF1EE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFD2E7D1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.shield,
                            color: Color(0xFF146F1B),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your privacy is important to us.',
                                  style: TextStyle(
                                    color: Color(0xFF1A3320),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'All information provided is secure and confidential.',
                                  style: TextStyle(
                                    color: Color(0xFF6E8D73),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF146F1B),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactDetailRow extends StatelessWidget {
  const _ContactDetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFECF1EE),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFF146F1B), size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF146F1B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF6E8D73),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
