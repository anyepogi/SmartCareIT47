import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartcare/screens/profile_patient_screen.dart';
import 'package:smartcare/screens/dashboard_screen.dart';
import 'package:smartcare/main.dart';
import 'package:smartcare/screens/appointment_screen.dart';
import 'package:smartcare/state/app_session.dart';

void main() {
  testWidgets('shows the SmartCare welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartCareApp(initialRoute: '/'));
    await tester.pumpAndSettle();

    expect(find.text('ABOUT US'), findsOneWidget);
    expect(find.text('CONTACT'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Terms and Condition'), findsOneWidget);
  });

  testWidgets('get started requires accepting terms before sign in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartCareApp(initialRoute: '/'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Terms and conditions'), findsOneWidget);
    expect(find.text('I agree'), findsOneWidget);

    await tester.tap(find.text('I agree'));
    await tester.pumpAndSettle();

    expect(find.text('SIGN IN'), findsOneWidget);
  });

  void testDashboardCardNavigation(String cardLabel, String targetLabel) {
    testWidgets('dashboard $cardLabel card opens its detail page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DashboardScreen(),
          routes: {
            '/queue': (_) => Scaffold(body: Center(child: Text(targetLabel))),
            '/visits': (_) => Scaffold(body: Center(child: Text(targetLabel))),
            '/appointment': (_) =>
                Scaffold(body: Center(child: Text(targetLabel))),
            '/results': (_) => Scaffold(body: Center(child: Text(targetLabel))),
          },
        ),
      );

      final card = find.ancestor(
        of: find.text(cardLabel),
        matching: find.byType(InkWell),
      );

      await tester.tap(card.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text(targetLabel), findsOneWidget);
    });
  }

  testDashboardCardNavigation('Queue #', 'Queue target');
  testDashboardCardNavigation('Visit this month', 'Visits target');
  testDashboardCardNavigation('Upcoming', 'Appointment target');
  testDashboardCardNavigation('Pending Results', 'Results target');

  testWidgets('appointment date selector updates when month changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppointmentBookingScreen(initialDate: DateTime(2026, 6, 15)),
      ),
    );

    expect(find.text('June\n2026'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    await tester.tap(find.text('July\n2026'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Wed'), findsWidgets);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm Appointment'));
    await tester.tap(find.text('Confirm Appointment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(
      find.textContaining('July 2, 2026 at 9:00am - 9:30am'),
      findsOneWidget,
    );
  });

  testWidgets('patient appointment flow skips symptoms and opens status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const AppointmentBookingScreen(),
        routes: {
          '/queue': (_) =>
              const Scaffold(body: Center(child: Text('Queue target'))),
        },
      ),
    );

    expect(find.textContaining('Symptom'), findsNothing);
    expect(find.textContaining('symptom'), findsNothing);

    await tester.ensureVisible(find.text('9:00am - 9:30am'));
    await tester.tap(find.text('9:00am - 9:30am'));
    await tester.ensureVisible(find.text('Confirm Appointment'));
    await tester.tap(find.text('Confirm Appointment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Confirm Appointment'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Appointment Saved'), findsOneWidget);

    await tester.tap(find.text('View Status'));
    await tester.pumpAndSettle();

    expect(find.text('Queue target'), findsOneWidget);
  });

  testWidgets('patient appointment flow suggests an alternative schedule', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const AppointmentBookingScreen(),
        routes: {
          '/queue': (_) =>
              const Scaffold(body: Center(child: Text('Queue target'))),
        },
      ),
    );

    await tester.ensureVisible(find.text('10:00am - 10:30am'));
    await tester.tap(find.text('10:00am - 10:30am'));
    await tester.ensureVisible(find.text('Confirm Appointment'));
    await tester.tap(find.text('Confirm Appointment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Alternative Schedule'), findsOneWidget);
    expect(
      find.textContaining('AI scheduling suggests 10:30am - 11:00am'),
      findsOneWidget,
    );
  });

  testWidgets('profile information rows can be edited', (
    WidgetTester tester,
  ) async {
    SmartCareSession.switchRole(UserRole.patient);
    SmartCareSession.updatePersonalInfo("Email", "mariasantos@gmail.com");
    SmartCareSession.updateMedicalInfo("Medical Condition", "Hypertension");

    await tester.pumpWidget(const MaterialApp(home: PatientProfileScreen()));

    await tester.ensureVisible(find.text('Email:'));
    await tester.tap(find.text('Email:'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Email'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'maria.updated@gmail.com');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('maria.updated@gmail.com'), findsOneWidget);

    await tester.ensureVisible(find.text('Medical Condition:'));
    await tester.tap(find.text('Medical Condition:'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Medical Condition'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Asthma');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Asthma'), findsOneWidget);
  });
}
