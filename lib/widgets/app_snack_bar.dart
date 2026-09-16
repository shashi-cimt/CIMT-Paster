import 'package:flutter/material.dart';

/// Centralized SnackBar utility for CIMT application.
/// Displays stylish, top-floating alerts with 3-second duration for red alerts.
class AppSnackBar {
  /// Shows a red error alert at the top of the screen lasting 3 seconds.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
  }) {
    showTopSnackBar(context, message, isError: true, duration: duration);
  }

  /// Shows a green success alert at the top of the screen lasting 3 seconds.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
  }) {
    showTopSnackBar(context, message, isError: false, duration: duration);
  }

  /// Shows a floating alert at the top of the screen.
  static void showTopSnackBar(
    BuildContext context,
    String message, {
    bool isError = true,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!context.mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final double topPadding = mediaQuery.padding.top;
    final double screenHeight = mediaQuery.size.height;
    // Calculate bottom margin so that the SnackBar floats directly beneath the top status / app bar
    final double bottomMargin = (screenHeight - topPadding - 80).clamp(
      16.0,
      screenHeight - 40,
    );

    final Color color = isError
        ? const Color(0xFFD32F2F)
        : const Color(0xFF2E7D32);
    final IconData icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(left: 16, right: 16, bottom: bottomMargin),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        padding: EdgeInsets.zero,
        content: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
