/// lib/widgets/scale_button.dart
///
/// A gesture-driven button that applies a subtle scale-down animation
/// on press, giving tactile feedback without any platform-specific chrome.
///
/// Used as a wrapper throughout the app wherever a custom-painted widget
/// needs to respond to taps (e.g. [CoachCard], back-arrow buttons, etc.).
library;
import 'package:flutter/material.dart';

/// Wraps any [child] widget with a press-down scale animation.
///
/// When the user presses the widget it shrinks to [scaleAmount] × its normal
/// size, then springs back on release. The [onPressed] callback fires on
/// a completed tap-up gesture.
class ScaleButton extends StatefulWidget {
  /// The widget to display inside the animated container.
  final Widget child;

  /// Callback invoked when the user completes a tap gesture.
  final VoidCallback onPressed;

  /// The scale factor applied while the button is pressed.
  /// Defaults to `0.95` (a 5 % shrink).
  final double scaleAmount;

  const ScaleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleAmount = 0.95,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Short duration so the button feels snappy.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleAmount,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Shrinks the widget when the user presses down.
  void _onTapDown(TapDownDetails details) => _controller.forward();

  /// Restores the widget size and fires [onPressed] when the tap is completed.
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  /// Restores the widget size if the tap is cancelled (e.g. the user drags away).
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
