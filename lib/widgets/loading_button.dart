import 'package:flutter/material.dart';

import 'animated_pressable.dart';

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.icon,
    this.style,
    this.indicatorColor = Colors.white,
    this.indicatorSize = 22,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;
  final Color indicatorColor;
  final double indicatorSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      enabled: !isLoading && onPressed != null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: indicatorSize,
                  height: indicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                  ),
                )
              : _ButtonContent(
                  key: const ValueKey('content'),
                  icon: icon,
                  child: child,
                ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({super.key, required this.child, this.icon});

  final Widget child;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    if (icon == null) {
      return FittedBox(fit: BoxFit.scaleDown, child: child);
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 8), child],
      ),
    );
  }
}
