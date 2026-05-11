/// lib/widgets/gradient_background.dart
///
/// A reusable dark-to-black gradient container used as the base layer
/// for multiple screens (e.g. [MyLessonsScreen], [AthleteMessagesScreen]).
///
/// Centralising the gradient here means a single edit propagates to every
/// screen that uses this widget.
library;
import 'package:flutter/material.dart';

/// Renders a full-screen dark-grey to black diagonal gradient behind [child].
class GradientBackground extends StatelessWidget {
  /// The widget tree to display on top of the gradient.
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 61, 59, 59), // Dark grey
            Color.fromARGB(255, 0, 0, 0),    // Pure black
          ],
        ),
      ),
      child: child,
    );
  }
}
