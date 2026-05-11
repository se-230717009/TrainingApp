/// lib/widgets/settings_menu_item.dart
///
/// A reusable settings list tile widget.
///
/// **Why this file exists:**
/// The `_buildMenuItem` private method was defined identically in both
/// [HomeScreen] and [CoachHomeScreen]. Any visual change to the settings
/// list items had to be made in two places. Extracting it into this shared
/// widget follows the **Don't Repeat Yourself (DRY)** principle and the
/// **Single Responsibility Principle**.

// ignore_for_file: deprecated_member_use

library;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single row in a settings-style list.
///
/// Shows an [icon], a [label], and an arrow indicator. When [isDestructive]
/// is `true`, the item and icon are rendered in red to visually signal a
/// dangerous action (e.g. "Log Out").
class SettingsMenuItem extends StatelessWidget {
  /// The leading icon displayed inside a rounded square container.
  final IconData icon;

  /// The label text shown next to the icon.
  final String label;

  /// Callback invoked when the user taps this item.
  final VoidCallback onTap;

  /// When `true`, the icon and label render in [Colors.redAccent] to indicate
  /// a destructive action (e.g. logout, delete).
  ///
  /// Defaults to `false`.
  final bool isDestructive;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    // Destructive items use red; all others use white on the dark background.
    final Color itemColor =
        isDestructive ? Colors.redAccent : Colors.white;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.redAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: itemColor, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: itemColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white12,
        size: 14,
      ),
      onTap: onTap,
    );
  }
}
