import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Care is a modern mobile healthcare system designed to provide a simpler, faster, and more convenient healthcare experience for everyone. Our goal is to connect patients and healthcare services through an accessible and user-friendly platform that supports better communication and care management.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF4A4A4A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'We believe that healthcare should be easy to access anytime and anywhere. With Smart Care, users can experience a smarter way of managing their healthcare needs through a reliable and efficient digital solution built with care and innovation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF4A4A4A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'At Smart Care, we are committed to improving healthcare accessibility by creating a system that values convenience, trust, and quality service for every user.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF4A4A4A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Mission, Vision, Values section
                        Row(
                          children: [
                            Expanded(
                              child: _missionVisionCard(
                                icon: Icons.check_circle_outline,
                                title: 'Our Mission',
                                description:
                                    'To provide accessible, efficient, and quality healthcare services through innovative technology',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _missionVisionCard(
                                icon: Icons.visibility_outlined,
                                title: 'Our Vision',
                                description:
                                    'To be a trusted digital healthcare companion for every individual and community',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Our Values',
                          style: TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _valueIcon(Icons.favorite_outline, 'Compassion'),
                            _valueIcon(Icons.shield_outlined, 'Integrity'),
                            _valueIcon(Icons.people_outline, 'Commitment'),
                            _valueIcon(Icons.star_outline, 'Excellence'),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Why Choose SmartCare section
                        const Text(
                          'Why Choose SmartCare?',
                          style: TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _benefitCard(
                                icon: Icons.card_giftcard,
                                title: 'Easy Access',
                                description: 'Healthcare anytime, anywhere',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _benefitCard(
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
                                icon: Icons.lock_outlined,
                                title: 'Secure & Private',
                                description: 'Your data is safe with us',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _benefitCard(
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
                              const Text(
                                'Thank you for choosing SmartCare.',
                                style: TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'We\'re here to make your healthcare simpler and better for you.',
                                style: TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Icon(
                                Icons.favorite,
                                color: Color(0xFF1B5E20),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
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
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: const Color(0xFF1B5E20), size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF6E8D73),
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF0F7ED),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFF1B5E20), size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1B5E20),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _benefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: const Color(0xFF1B5E20), size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
