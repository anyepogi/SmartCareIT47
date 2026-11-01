import 'package:flutter/material.dart';

import '../state/app_session.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_bottom_nav.dart' show smartCareGoTo;

class AboutUsRoleScreen extends StatelessWidget {
  const AboutUsRoleScreen({super.key});

  void _goBackToMenu(BuildContext context) {
    final menuRoute = SmartCareSession.currentRole == UserRole.patient
        ? '/menu'
        : '/menu-doctor-nurse';
    smartCareGoTo(context, menuRoute);
  }

  @override
  Widget build(BuildContext context) {
    // Tablets (wider than 800px) get the tablet background, a 900px
    // content column and larger text; phones keep their layout.
    final isTablet = MediaQuery.sizeOf(context).width > 800;
    final paragraphStyle = isTablet
        ? const TextStyle(color: Colors.black87, fontSize: 17, height: 1.5)
        : const TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.6,
          );
    final sectionTitleStyle = TextStyle(
      color: const Color(0xFF1B5E20),
      fontSize: isTablet ? 23 : 14,
      fontWeight: isTablet ? FontWeight.bold : FontWeight.w600,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isTablet ? 'assets/bg1_tab.png' : 'assets/bg1.png',
                ),
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
                        onTap: () => _goBackToMenu(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1A3320),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Logo and branding
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.1),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset('assets/logo.png'),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Smart',
                                style: TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: 'Care',
                                style: TextStyle(
                                  color: Color(0xFF8BC34A),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ABOUT US',
                          style: TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description content
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 900 : double.infinity,
                      ),
                      child: Padding(
                        padding: isTablet
                            ? const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              )
                            : const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 720 : double.infinity,
                                ),
                                child: Text(
                                  'Smart Care is a modern mobile healthcare system designed to provide a simpler, faster, and more convenient healthcare experience for everyone. Our goal is to connect patients and healthcare services through an accessible and user-friendly platform that supports better communication and care management.',
                                  textAlign: TextAlign.center,
                                  style: paragraphStyle,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 720 : double.infinity,
                                ),
                                child: Text(
                                  'We believe that healthcare should be easy to access anytime and anywhere. With Smart Care, users can experience a smarter way of managing their healthcare needs through a reliable and efficient digital solution built with care and innovation.',
                                  textAlign: TextAlign.center,
                                  style: paragraphStyle,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 720 : double.infinity,
                                ),
                                child: Text(
                                  'At Smart Care, we are committed to improving healthcare accessibility by creating a system that values convenience, trust, and quality service for every user.',
                                  textAlign: TextAlign.center,
                                  style: paragraphStyle,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Mission, Vision, Values section
                            Row(
                              children: [
                                Expanded(
                                  child: _missionVisionCard(
                                    tablet: isTablet,
                                    icon: Icons.check_circle_outline,
                                    title: 'Our Mission',
                                    description:
                                        'To provide accessible, efficient, and quality healthcare services through innovative technology',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _missionVisionCard(
                                    tablet: isTablet,
                                    icon: Icons.visibility_outlined,
                                    title: 'Our Vision',
                                    description:
                                        'To be a trusted digital healthcare companion for every individual and community',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Our Values', style: sectionTitleStyle),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _valueIcon(
                                  Icons.favorite_outline,
                                  'Compassion',
                                  isTablet,
                                ),
                                _valueIcon(
                                  Icons.shield_outlined,
                                  'Integrity',
                                  isTablet,
                                ),
                                _valueIcon(
                                  Icons.people_outline,
                                  'Commitment',
                                  isTablet,
                                ),
                                _valueIcon(
                                  Icons.star_outline,
                                  'Excellence',
                                  isTablet,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Why Choose SmartCare section
                            Text(
                              'Why Choose SmartCare?',
                              style: sectionTitleStyle,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _benefitCard(
                                    tablet: isTablet,
                                    icon: Icons.card_giftcard,
                                    title: 'Easy Access',
                                    description: 'Healthcare anytime, anywhere',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _benefitCard(
                                    tablet: isTablet,
                                    icon: Icons.schedule_outlined,
                                    title: 'Save Time',
                                    description:
                                        'Simplify appointments and medical testing',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _benefitCard(
                                    tablet: isTablet,
                                    icon: Icons.lock_outlined,
                                    title: 'Secure & Private',
                                    description: 'Your data is safe with us',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _benefitCard(
                                    tablet: isTablet,
                                    icon: Icons.psychology_outlined,
                                    title: 'Patient-Centered',
                                    description: 'Designed with care in mind',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Thank you message
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Thank you for choosing SmartCare.',
                                    style: isTablet
                                        ? const TextStyle(
                                            color: Color(0xFF1B5E20),
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          )
                                        : const TextStyle(
                                            color: Color(0xFF4A4A4A),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'We\'re here to make your healthcare simpler and better for you.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF4A4A4A),
                                      fontSize: isTablet ? 16 : 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Icon(
                                    Icons.favorite,
                                    color: Color(0xFF1B5E20),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isTablet ? 40 : 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _missionVisionCard({
    required IconData icon,
    required String title,
    required String description,
    bool tablet = false,
  }) {
    return Container(
      padding: EdgeInsets.all(tablet ? 20 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tablet)
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F7ED),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1B5E20), size: 24),
            )
          else
            Icon(icon, color: const Color(0xFF1B5E20), size: 24),
          SizedBox(height: tablet ? 12 : 8),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF1B5E20),
              fontSize: tablet ? 20 : 12,
              fontWeight: tablet ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          SizedBox(height: tablet ? 8 : 6),
          Text(
            description,
            style: tablet
                ? const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    height: 1.4,
                  )
                : const TextStyle(
                    color: Color(0xFF6E8D73),
                    fontSize: 10,
                    height: 1.3,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _valueIcon(IconData icon, String label, [bool tablet = false]) {
    return Column(
      children: [
        Container(
          width: tablet ? 58 : 50,
          height: tablet ? 58 : 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF0F7ED),
          ),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF1B5E20),
              size: tablet ? 30 : 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF1B5E20),
            fontSize: tablet ? 16 : 11,
            fontWeight: tablet ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _benefitCard({
    required IconData icon,
    required String title,
    required String description,
    bool tablet = false,
  }) {
    return Container(
      padding: tablet
          ? const EdgeInsets.symmetric(vertical: 20, horizontal: 16)
          : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1B5E20), size: tablet ? 36 : 32),
          SizedBox(height: tablet ? 12 : 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF1B5E20),
              fontSize: tablet ? 19 : 12,
              fontWeight: tablet ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          SizedBox(height: tablet ? 8 : 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: tablet
                ? const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    height: 1.4,
                  )
                : const TextStyle(
                    color: Color(0xFF6E8D73),
                    fontSize: 10,
                    height: 1.3,
                  ),
          ),
        ],
      ),
    );
  }
}
