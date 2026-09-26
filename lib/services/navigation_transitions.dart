import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SmartCareTransition { appear, subPage, auth }

class SmartCareDashboardBackGuard extends StatelessWidget {
  const SmartCareDashboardBackGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmExit(context);
        }
      },
      child: child,
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit SmartCare?'),
        content: const Text('Are you sure you want to exit SmartCare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      await SystemNavigator.pop();
    }
  }
}

Route<T> smartCareRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  SmartCareTransition transition = SmartCareTransition.appear,
}) {
  final duration = switch (transition) {
    SmartCareTransition.appear => Duration.zero,
    SmartCareTransition.subPage => const Duration(milliseconds: 200),
    SmartCareTransition.auth => const Duration(milliseconds: 225),
  };

  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (transition) {
        case SmartCareTransition.appear:
          return child;
        case SmartCareTransition.subPage:
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          );
        case SmartCareTransition.auth:
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
      }
    },
  );
}
