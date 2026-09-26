import 'package:flutter/material.dart';

class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final bool enabled;
  final double scale;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value || !mounted) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pressed) {
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: widget.enabled && _pressed ? widget.scale : 1,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
