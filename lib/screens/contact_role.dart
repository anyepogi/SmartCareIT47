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
<<<<<<< HEAD
    // Tablets (wider than 800px) get the tablet background, a 900px column,
    // a 2-column contact list and larger text; phones keep their layout.
    final isTablet = MediaQuery.sizeOf(context).width > 800;
    final labelStyle = isTablet
        ? const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          )
        : const TextStyle(
            color: Color(0xFF1A3320),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
    final hintStyle = TextStyle(
      color: isTablet ? Colors.grey.shade600 : const Color(0xFFA8BDA5),
      fontSize: isTablet ? 17 : null,
    );
    final inputStyle = TextStyle(fontSize: isTablet ? 17 : null);
    final fieldIconSize = isTablet ? 24.0 : 20.0;

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
<<<<<<< HEAD
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isTablet ? 'assets/bg1_tab.png' : 'assets/bg1.png',
                ),
=======
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg1.png'),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
                          color: Colors.white,
=======
                          color: Color(0xFF1A3320),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
                          size: 24,
                        ),
                      ),
                    ),
                  ),
<<<<<<< HEAD
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 900 : double.infinity,
                      ),
                      child: Padding(
                        // Sections already have 16px sides; tablets add 8
                        // more (24 total) plus 20 top and bottom.
                        padding: isTablet
                            ? const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 20,
                              )
                            : EdgeInsets.zero,
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              // Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Contact Us',
                                      style: TextStyle(
                                        color: Color(0xFF006738),
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'We\'re here to help! Reach out to us\nfor any questions or concerns.',
                                      style: isTablet
                                          ? const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                              height: 1.5,
                                            )
                                          : const TextStyle(
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(isTablet ? 24 : 16),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Name', style: labelStyle),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _nameController,
                                        style: inputStyle,
                                        decoration: InputDecoration(
                                          hintText: 'Enter your name...',
                                          hintStyle: hintStyle,
                                          prefixIcon: Icon(
                                            Icons.person,
                                            color: const Color(0xFF146F1B),
                                            size: fieldIconSize,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE3EFE1),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE3EFE1),
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text('Email', style: labelStyle),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _emailController,
                                        style: inputStyle,
                                        decoration: InputDecoration(
                                          hintText: 'Enter your email...',
                                          hintStyle: hintStyle,
                                          prefixIcon: Icon(
                                            Icons.mail,
                                            color: const Color(0xFF146F1B),
                                            size: fieldIconSize,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE3EFE1),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE3EFE1),
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text('Your concern', style: labelStyle),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _concernController,
                                        style: inputStyle,
                                        maxLines: 5,
                                        maxLength: 500,
                                        onChanged: (value) {
                                          setState(() {
                                            _concernLength = value.length;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Enter your concern...',
                                          hintStyle: hintStyle,
                                          prefixIcon: Icon(
                                            Icons.edit,
                                            color: const Color(0xFF146F1B),
                                            size: fieldIconSize,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE3EFE1),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE3EFE1),
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
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
                                          style: TextStyle(
                                            color: const Color(0xFF9CB0A0),
                                            fontSize: isTablet ? 13 : 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        height: isTablet ? 54 : 44,
                                        child: ElevatedButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : _submitContactForm,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF146F1B,
                                            ),
                                            disabledBackgroundColor:
                                                const Color(
                                                  0xFF146F1B,
                                                ).withValues(alpha: 0.6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    isTablet ? 14 : 8,
                                                  ),
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
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.send,
                                                      color: Colors.white,
                                                      size: isTablet ? 22 : 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Send Message',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: isTablet
                                                            ? 18
                                                            : 14,
                                                        fontWeight: isTablet
                                                            ? FontWeight.bold
                                                            : FontWeight.w600,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(isTablet ? 24 : 16),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Contact Details',
                                        style: TextStyle(
                                          color: const Color(0xFF1A3320),
                                          fontSize: isTablet ? 21 : 14,
                                          fontWeight: isTablet
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Tablets: addresses on the left, phone and email on
                                      // the right. Phones: one stacked list.
                                      if (isTablet)
                                        const Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  _ContactDetailRow(
                                                    icon: Icons.location_on,
                                                    title: 'Sta. Rita',
                                                    value:
                                                        '100 C Mariano, San Vicente, Sta. Rita, Pampanga (AQM Pharmacy)',
                                                    large: true,
                                                  ),
                                                  SizedBox(height: 16),
                                                  _ContactDetailRow(
                                                    icon: Icons.location_on,
                                                    title: 'Guagua',
                                                    value:
                                                        'Annex 1 Room 102, RMC Medical Arts Building, San Roque, Guagua, Pampanga',
                                                    large: true,
                                                  ),
                                                  SizedBox(height: 16),
                                                  _ContactDetailRow(
                                                    icon: Icons.location_on,
                                                    title: 'Lubao',
                                                    value:
                                                        'J.P. Rizal St., Sta. Cruz, Lubao, Pampanga (Diagnostic Center Laboratory)',
                                                    large: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 24),
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  _ContactDetailRow(
                                                    icon: Icons.phone,
                                                    title: 'Contact No.',
                                                    value:
                                                        'Globe: 09176294108\nSun: 09424407691',
                                                    large: true,
                                                  ),
                                                  SizedBox(height: 16),
                                                  _ContactDetailRow(
                                                    icon: Icons.mail,
                                                    title: 'Email',
                                                    value:
                                                        'smartcare.support@gmail.com',
                                                    large: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      else ...[
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
                                          value:
                                              'Globe: 09176294108\nSun: 09424407691',
                                        ),
                                        const SizedBox(height: 16),
                                        // Email
                                        _ContactDetailRow(
                                          icon: Icons.mail,
                                          title: 'Email',
                                          value: 'smartcare.support@gmail.com',
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Privacy notice
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
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
                                    children: [
                                      Icon(
                                        Icons.shield,
                                        color: const Color(0xFF146F1B),
                                        size: isTablet ? 24 : 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Your privacy is important to us.',
                                              style: TextStyle(
                                                color: const Color(0xFF1A3320),
                                                fontSize: isTablet ? 16 : 12,
                                                fontWeight: isTablet
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'All information provided is secure and confidential.',
                                              style: isTablet
                                                  ? const TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 14.5,
                                                    )
                                                  : const TextStyle(
                                                      color: Color(0xFF6E8D73),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF146F1B),
                                        size: isTablet ? 24 : 20,
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
                    ),
                  ),
=======
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
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
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
<<<<<<< HEAD
    this.large = false,
=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
  });

  final IconData icon;
  final String title;
  final String value;

<<<<<<< HEAD
  /// Tablet styling: bigger badge, title and text.
  final bool large;

=======
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
<<<<<<< HEAD
          width: large ? 46 : 36,
          height: large ? 46 : 36,
          decoration: BoxDecoration(
            color: large ? const Color(0xFFEAF7EA) : const Color(0xFFECF1EE),
            borderRadius: BorderRadius.circular(large ? 10 : 6),
          ),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF146F1B),
              size: large ? 24 : 18,
            ),
=======
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFECF1EE),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFF146F1B), size: 18),
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
<<<<<<< HEAD
                style: TextStyle(
                  color: const Color(0xFF146F1B),
                  fontSize: large ? 18 : 12,
                  fontWeight: large ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              SizedBox(height: large ? 4 : 2),
              Text(
                value,
                style: large
                    ? const TextStyle(
                        color: Colors.black87,
                        fontSize: 15.5,
                        height: 1.4,
                      )
                    : const TextStyle(
                        color: Color(0xFF6E8D73),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
=======
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
>>>>>>> 4995fb1d0934045d389f7d2f88d3f93de5b6a13a
              ),
            ],
          ),
        ),
      ],
    );
  }
}
