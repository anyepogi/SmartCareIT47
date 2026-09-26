import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const primaryGreen = Color(0xFF008D4C);
  static const lightGreen = Color(0xFF8BC34A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF7),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        children: [
                          const SizedBox(height: 15),

                          /// TOP MENU
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/about');
                                },
                                child: const Text(
                                  "ABOUT US",
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/contact');
                                },
                                child: const Text(
                                  "CONTACT",
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          /// LOGO
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.08),
                                  blurRadius: 25,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Image.asset("assets/logo.png"),
                            ),
                          ),

                          const SizedBox(height: 8),

                          /// TITLE
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: "Smart",
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: "Care",
                                  style: TextStyle(
                                    color: lightGreen,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              "Your trusted mobile healthcare companion,\n"
                              "designed to make healthcare simpler,\n"
                              "smarter, and more accessible anytime, anywhere.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                color: Color(0xFF444444),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// ILLUSTRATION
                          Container(
                            width: double.infinity,
                            height: 250,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Image.asset(
                              "assets/onboarding.png",
                              fit: BoxFit.cover,
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// BUTTON
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: _GetStartedButton(
                                onPressed: () {
                                  _showTermsDialog(context);
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 120),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "SmartCare Features",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.82,
                            children: const [
                              FeatureCard(
                                icon: Icons.smart_toy_outlined,
                                title: "AI Scheduling",
                                description:
                                    "Automatically suggests the best appointment schedule.",
                              ),
                              FeatureCard(
                                icon: Icons.location_on_outlined,
                                title: "Geofence Tracking",
                                description:
                                    "Track doctor arrival and clinic presence in real time.",
                              ),
                              FeatureCard(
                                icon: Icons.notifications_active_outlined,
                                title: "Smart Alerts",
                                description:
                                    "Receive reminders and appointment notifications instantly.",
                              ),
                              FeatureCard(
                                icon: Icons.assignment_outlined,
                                title: "Medical Records",
                                description:
                                    "Secure access to consultation history and health records.",
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "How SmartCare Works",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          const Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 15,
                            children: [
                              ProcessItem(
                                icon: Icons.calendar_month,
                                title: "Book\nAppointment",
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: WelcomeScreen.primaryGreen,
                                ),
                              ),

                              ProcessItem(
                                icon: Icons.psychology,
                                title: "AI\nSchedule",
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: WelcomeScreen.primaryGreen,
                                ),
                              ),

                              ProcessItem(
                                icon: Icons.medical_services,
                                title: "Doctor\nCheck-In",
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: WelcomeScreen.primaryGreen,
                                ),
                              ),

                              ProcessItem(
                                icon: Icons.groups,
                                title: "Queue\nMonitor",
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: WelcomeScreen.primaryGreen,
                                ),
                              ),

                              ProcessItem(
                                icon: Icons.notifications,
                                title: "Get\nUpdates",
                              ),
                            ],
                          ),

                          const SizedBox(height: 35),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7EA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 32,
                                    color: WelcomeScreen.primaryGreen,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Your Health. Our Priority.",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: WelcomeScreen.primaryGreen,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "SmartCare provides a secure, efficient and smarter healthcare experience.",
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.lock,
                                    color: WelcomeScreen.primaryGreen,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    // FOOTER - FULL WIDTH (outside Padding)
                    ClipPath(
                      clipper: CurvedTopClipper(),
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFF16751F),
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Column(
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/terms');
                              },
                              child: const Text(
                                'Terms and Conditions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '© 2026 SmartCare. All rights reserved.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
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
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Terms and Conditions"),
          content: const SingleChildScrollView(
            child: Text(
              "By using SmartCare, you agree to our terms and conditions. "
              "Your information will be handled securely and responsibly.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/sign-in');
              },
              child: const Text("I Agree"),
            ),
          ],
        );
      },
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final Color green = WelcomeScreen.primaryGreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 45, color: green),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class ProcessItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const ProcessItem({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFEAF7EA),
            child: Icon(icon, size: 30, color: WelcomeScreen.primaryGreen),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: WelcomeScreen.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _GetStartedButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _GetStartedButton({required this.onPressed});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 8, end: 12).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: WelcomeScreen.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: _elevationAnimation.value,
              ),
              child: const Text(
                "Get Started",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CurvedTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 40);
    final firstControlPoint = Offset(size.width / 2, 0);
    final firstPoint = Offset(size.width, 40);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstPoint.dx,
      firstPoint.dy,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CurvedTopClipper oldClipper) => false;
}
