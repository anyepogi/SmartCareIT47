import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static const primaryGreen = Color(0xFF008D4C);
  static const lightGreen = Color(0xFF8BC34A);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _splashController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoTranslateX;
  late final Animation<double> _textFadeIn;
  late final Animation<double> _textTranslateX;
  late final Animation<Offset> _splashSlideUp;
  bool _isSplashVisible = true;

  @override
  void initState() {
    super.initState();
    _splashController = AnimationController(
      duration: const Duration(milliseconds: 3800),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 4.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeInOutCubic),
      ),
    );

    _logoTranslateX = Tween<double>(begin: 0, end: -75).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.30, 0.45, curve: Curves.easeInOutCubic),
      ),
    );

    _textFadeIn = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.35, 0.50, curve: Curves.easeOut),
    );

    _textTranslateX = Tween<double>(begin: -40, end: 60).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.35, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    _splashSlideUp = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
        .animate(
          CurvedAnimation(
            parent: _splashController,
            curve: const Interval(0.85, 1.0, curve: Curves.easeInOutQuart),
          ),
        );

    _splashController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _isSplashVisible = false);
      }
    });
    _splashController.forward();
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF7),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return _buildTabletContent(context);
              }
              return _buildMobileContent(context);
            },
          ),
          if (_isSplashVisible) _buildSplashOverlay(),
        ],
      ),
    );
  }

  // ==========================================
  // 1. MOBILE LAYOUT
  // ==========================================
  Widget _buildMobileContent(BuildContext context) {
    const primaryGreen = WelcomeScreen.primaryGreen;
    const lightGreen = WelcomeScreen.lightGreen;

    return Column(
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
                        const SizedBox(height: 8),

                        /// TOP HEADER
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Image.asset(
                                    "assets/logo.png",
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Smart",
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "Care",
                                        style: TextStyle(
                                          color: lightGreen,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/about'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    "ABOUT US",
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/contact'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    "CONTACT",
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Divider(
                          color: primaryGreen.withValues(alpha: 0.15),
                          thickness: 1,
                        ),
                        const SizedBox(height: 28),

                        /// MAIN HERO TITLE
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: "Smart",
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: "Care",
                                style: TextStyle(
                                  color: lightGreen,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            "Your trusted companion for simpler,\n"
                            "smarter healthcare.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        /// MAIN ILLUSTRATION
                        Container(
                          width: double.infinity,
                          height: 340,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Image.asset(
                            "assets/onboarding.png",
                            fit: BoxFit.contain,
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
                              onPressed: () => _showTermsDialog(context),
                            ),
                          ),
                        ),

                        const SizedBox(height: 200),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "SmartCare Features",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: primaryGreen,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.88,
                          children: const [
                            _FeatureCard(
                              icon: Icons.smart_toy_rounded,
                              title: "AI Scheduling",
                              description:
                                  "Automatically suggest the best appointment schedule.",
                            ),
                            _FeatureCard(
                              icon: Icons.groups_rounded,
                              title: "Real-Time Queue",
                              description:
                                  "View queue position and estimated waiting time.",
                            ),
                            _FeatureCard(
                              icon: Icons.location_on_rounded,
                              title: "Geofence Tracker",
                              description:
                                  "Track doctor arrival and clinic presence in real time.",
                            ),
                            _FeatureCard(
                              icon: Icons.notifications_rounded,
                              title: "Smart Alerts",
                              description:
                                  "Receive appointment reminders and appointment updates.",
                            ),
                            _FeatureCard(
                              icon: Icons.event_note_rounded,
                              title: "Appointment Management",
                              description:
                                  "View, reschedule, or cancel appointments.",
                            ),
                            _FeatureCard(
                              icon: Icons.qr_code_scanner_rounded,
                              title: "QR Tutorials",
                              description:
                                  "Scan clinic QR codes to watch app tutorials.",
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "How SmartCare Works",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: primaryGreen,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: 0.06),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            children: [
                              _WorkStepItem(
                                stepNumber: "1",
                                icon: Icons.calendar_month_rounded,
                                title: "Book Appointment",
                              ),
                              Divider(height: 1, color: Color(0xFFEEEEEE)),
                              _WorkStepItem(
                                stepNumber: "2",
                                icon: Icons.psychology_rounded,
                                title: "AI Schedule",
                              ),
                              Divider(height: 1, color: Color(0xFFEEEEEE)),
                              _WorkStepItem(
                                stepNumber: "3",
                                icon: Icons.location_on_rounded,
                                title: "Check Doctor Availability",
                              ),
                              Divider(height: 1, color: Color(0xFFEEEEEE)),
                              _WorkStepItem(
                                stepNumber: "4",
                                icon: Icons.groups_rounded,
                                title: "Monitor Your Queue",
                              ),
                              Divider(height: 1, color: Color(0xFFEEEEEE)),
                              _WorkStepItem(
                                stepNumber: "5",
                                icon: Icons.notifications_rounded,
                                title: "Receive Updates",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: 0.06),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Access our SmartCare Tutorial Video",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: Image.asset(
                                  "assets/qr.png",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        Container(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                Icons.lock_outline,
                                color: WelcomeScreen.primaryGreen,
                                size: 26,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  /// FOOTER
                  ClipPath(
                    clipper: _CurvedTopClipper(),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFF16751F),
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/terms'),
                            child: const Text(
                              'Terms and Conditions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            '© 2026 SmartCare. All rights reserved.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 15),
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
    );
  }

  // ==========================================
  // 2. TABLET LAYOUT
  // ==========================================
  Widget _buildTabletContent(BuildContext context) {
    const primaryGreen = WelcomeScreen.primaryGreen;
    const lightGreen = WelcomeScreen.lightGreen;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  /// TOP HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: Image.asset(
                                "assets/logo.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 8),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Smart",
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "Care",
                                    style: TextStyle(
                                      color: lightGreen,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/about'),
                              child: const Text(
                                "ABOUT US",
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/contact'),
                              child: const Text(
                                "CONTACT",
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Divider(
                      color: primaryGreen.withValues(alpha: 0.15),
                      thickness: 1,
                    ),
                  ),
                  const SizedBox(height: 48),

                  /// HERO SECTION
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1050),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Smart",
                                          style: TextStyle(
                                            color: primaryGreen,
                                            fontSize: 52,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "Care",
                                          style: TextStyle(
                                            color: lightGreen,
                                            fontSize: 52,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    "Your trusted companion for simpler,\nsmarter healthcare.",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                      color: Color(0xFF555555),
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                  SizedBox(
                                    width: 230,
                                    height: 52,
                                    child: _GetStartedButton(
                                      onPressed: () =>
                                          _showTermsDialog(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Flexible(
                              flex: 6,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: 480,
                                  child: Image.asset(
                                    "assets/onboarding.png",
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 140),

                  /// CONSTRAINED BODY CONTENT
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1050),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "SmartCare Features",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 0.95,
                              children: const [
                                _FeatureCard(
                                  icon: Icons.smart_toy_rounded,
                                  title: "AI Scheduling",
                                  description:
                                      "Automatically suggest the best appointment schedule.",
                                  isTablet: true,
                                ),
                                _FeatureCard(
                                  icon: Icons.groups_rounded,
                                  title: "Real-Time Queue",
                                  description:
                                      "View queue position and estimated waiting time.",
                                  isTablet: true,
                                ),
                                _FeatureCard(
                                  icon: Icons.location_on_rounded,
                                  title: "Geofence Tracker",
                                  description:
                                      "Track doctor arrival and clinic presence in real time.",
                                  isTablet: true,
                                ),
                                _FeatureCard(
                                  icon: Icons.notifications_rounded,
                                  title: "Smart Alerts",
                                  description:
                                      "Receive appointment reminders and appointment updates.",
                                  isTablet: true,
                                ),
                                _FeatureCard(
                                  icon: Icons.event_note_rounded,
                                  title: "Appointment Management",
                                  description:
                                      "View, reschedule, or cancel appointments.",
                                  isTablet: true,
                                ),
                                _FeatureCard(
                                  icon: Icons.qr_code_scanner_rounded,
                                  title: "QR Tutorials",
                                  description:
                                      "Scan clinic QR codes to watch app tutorials.",
                                  isTablet: true,
                                ),
                              ],
                            ),

                            const SizedBox(height: 64),

                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "How SmartCare Works",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGreen.withValues(alpha: 0.06),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Column(
                                children: [
                                  _WorkStepItem(
                                    stepNumber: "1",
                                    icon: Icons.calendar_month_rounded,
                                    title: "Book Appointment",
                                  ),
                                  Divider(height: 1, color: Color(0xFFEEEEEE)),
                                  _WorkStepItem(
                                    stepNumber: "2",
                                    icon: Icons.psychology_rounded,
                                    title: "AI Schedule",
                                  ),
                                  Divider(height: 1, color: Color(0xFFEEEEEE)),
                                  _WorkStepItem(
                                    stepNumber: "3",
                                    icon: Icons.location_on_rounded,
                                    title: "Check Doctor Availability",
                                  ),
                                  Divider(height: 1, color: Color(0xFFEEEEEE)),
                                  _WorkStepItem(
                                    stepNumber: "4",
                                    icon: Icons.groups_rounded,
                                    title: "Monitor Your Queue",
                                  ),
                                  Divider(height: 1, color: Color(0xFFEEEEEE)),
                                  _WorkStepItem(
                                    stepNumber: "5",
                                    icon: Icons.notifications_rounded,
                                    title: "Receive Updates",
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGreen.withValues(alpha: 0.06),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "Access our SmartCare Tutorial Video",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Image.asset(
                                      "assets/qr.png",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7EA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 36,
                                    color: WelcomeScreen.primaryGreen,
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Your Health. Our Priority.",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: WelcomeScreen.primaryGreen,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "SmartCare provides a secure, efficient and smarter healthcare experience.",
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.lock_outline,
                                    color: WelcomeScreen.primaryGreen,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// FOOTER
                  ClipPath(
                    clipper: _CurvedTopClipper(),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFF16751F),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/terms'),
                            child: const Text(
                              'Terms and Conditions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '© 2026 SmartCare. All rights reserved.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildSplashOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _splashController,
        builder: (context, child) {
          return SlideTransition(
            position: _splashSlideUp,
            child: ClipPath(
              clipper: _BottomCurvedClipper(
                curveHeight: 30 * _splashSlideUp.value.dy.abs(),
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFF8FCF7),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(_textTranslateX.value, 0),
                      child: FadeTransition(
                        opacity: _textFadeIn,
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(
                                text: "Smart",
                                style: TextStyle(
                                  color: WelcomeScreen.primaryGreen,
                                ),
                              ),
                              TextSpan(
                                text: "Care",
                                style: TextStyle(
                                  color: WelcomeScreen.lightGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(_logoTranslateX.value, 0),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: Image.asset(
                            "assets/logo.png",
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.health_and_safety,
                                  size: 100,
                                  color: WelcomeScreen.primaryGreen,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Tablets (wider than 800px) get a fixed-width dialog with larger
        // text, matching the Sign Out dialog; phones keep the default.
        final tablet = MediaQuery.sizeOf(dialogContext).width > 800;
        const buttonText = TextStyle(fontSize: 17, fontWeight: FontWeight.bold);
        const buttonPadding = EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 14,
        );

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tablet ? 24 : 20),
          ),
          titlePadding: tablet
              ? const EdgeInsets.fromLTRB(32, 32, 32, 0)
              : null,
          contentPadding: tablet
              ? const EdgeInsets.fromLTRB(32, 16, 32, 8)
              : null,
          actionsPadding: tablet
              ? const EdgeInsets.fromLTRB(24, 8, 24, 20)
              : null,
          title: Text(
            "Terms and Conditions",
            style: tablet
                ? const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)
                : null,
          ),
          content: SizedBox(
            width: tablet ? 440 : null,
            child: SingleChildScrollView(
              child: Text(
                "By using SmartCare, you agree to our terms and conditions. "
                "Your information will be handled securely and responsibly.",
                style: tablet
                    ? const TextStyle(fontSize: 18, height: 1.4)
                    : null,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: tablet
                  ? TextButton.styleFrom(
                      padding: buttonPadding,
                      textStyle: buttonText,
                    )
                  : null,
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/sign-in');
              },
              style: tablet
                  ? ElevatedButton.styleFrom(
                      padding: buttonPadding,
                      textStyle: buttonText,
                    )
                  : null,
              child: const Text("I Agree"),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// HELPER COMPONENTS
// ==========================================

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isTablet;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    const green = WelcomeScreen.primaryGreen;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 24 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isTablet ? 54 : 48, color: green),
          SizedBox(height: isTablet ? 16 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: green,
                fontWeight: FontWeight.w800,
                fontSize: isTablet ? 18 : 16,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 13.5 : 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkStepItem extends StatelessWidget {
  final String stepNumber;
  final IconData icon;
  final String title;

  const _WorkStepItem({
    required this.stepNumber,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = WelcomeScreen.primaryGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEAF7EA),
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, color: primaryGreen, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
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

class _CurvedTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 20);
    final firstControlPoint = Offset(size.width / 2, 0);
    final firstPoint = Offset(size.width, 20);
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
  bool shouldReclip(_CurvedTopClipper oldClipper) => false;
}

class _BottomCurvedClipper extends CustomClipper<Path> {
  const _BottomCurvedClipper({required this.curveHeight});

  final double curveHeight;

  @override
  Path getClip(Size size) {
    final curve = curveHeight.clamp(0.0, size.height).toDouble();
    final path = Path()
      ..lineTo(0, size.height - curve)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + curve,
        size.width,
        size.height - curve,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_BottomCurvedClipper oldClipper) =>
      oldClipper.curveHeight != curveHeight;
}
