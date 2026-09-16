import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/fonts.dart';

/// A custom circular spinner matching the CAN IMAGE brand design.
///
/// Features 12 radial capsule-shaped ticks:
/// - 4 active ticks in brand orange/gold gradient ([Font.orangeColor] / [accentColor])
///   positioned at 9, 10, 11, 12 o'clock by default.
/// - 8 base ticks in deep brand navy ([Font.primaryColor] / [primaryColor]).
/// - Silky-smooth 60fps continuous clockwise rotation (or optional discrete tick-stepping).
class CanImageSpinner extends StatefulWidget {
  /// Diameter of the spinner in logical pixels.
  final double size;

  /// Base color for the 8 standard ticks. Defaults to [Font.primaryColor].
  final Color? primaryColor;

  /// Highlight color for the 4 active ticks. Defaults to [Font.orangeColor].
  final Color? accentColor;

  /// Optional lighter accent color for a subtle gradient across the 4 active ticks.
  /// Defaults to [Color(0xFFFFA726)] (amber/gold).
  final Color? accentEndColor;

  /// Duration for one complete 360-degree rotation. Defaults to 1200ms.
  final Duration duration;

  /// Total number of radial ticks (capsules). Default is 12.
  final int tickCount;

  /// Number of consecutive highlighted ticks. Default is 4.
  final int highlightCount;

  /// If true, rotation snaps discretely per tick (like classic iOS indicator).
  /// If false, rotates with silky-smooth continuous rotation.
  final bool isDiscrete;

  /// If true, spins counter-clockwise. Default is false (clockwise).
  final bool reverse;

  /// Ratio of inner hole radius to total radius (0.0 to 1.0). Default is 0.54.
  final double innerRadiusRatio;

  /// Ratio of outer edge radius to total radius (0.0 to 1.0). Default is 0.90.
  final double outerRadiusRatio;

  const CanImageSpinner({
    super.key,
    this.size = 48.0,
    this.primaryColor,
    this.accentColor,
    this.accentEndColor,
    this.duration = const Duration(milliseconds: 1200),
    this.tickCount = 12,
    this.highlightCount = 4,
    this.isDiscrete = false,
    this.reverse = false,
    this.innerRadiusRatio = 0.54,
    this.outerRadiusRatio = 0.90,
  });

  @override
  State<CanImageSpinner> createState() => _CanImageSpinnerState();
}

class _CanImageSpinnerState extends State<CanImageSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant CanImageSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectivePrimary = widget.primaryColor ?? Font.primaryColor;
    final effectiveAccent = widget.accentColor ?? Font.orangeColor;
    final effectiveAccentEnd =
        widget.accentEndColor ?? const Color(0xFFFFA726);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double progress = _controller.value;
            if (widget.isDiscrete) {
              progress =
                  (progress * widget.tickCount).floor() / widget.tickCount;
            }

            final angle =
                (widget.reverse ? -1.0 : 1.0) * progress * 2 * math.pi;

            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _CanImageSpinnerPainter(
                rotationAngle: angle,
                primaryColor: effectivePrimary,
                accentColor: effectiveAccent,
                accentEndColor: effectiveAccentEnd,
                tickCount: widget.tickCount,
                highlightCount: widget.highlightCount,
                innerRadiusRatio: widget.innerRadiusRatio,
                outerRadiusRatio: widget.outerRadiusRatio,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for the 12 radial capsules.
class _CanImageSpinnerPainter extends CustomPainter {
  final double rotationAngle;
  final Color primaryColor;
  final Color accentColor;
  final Color accentEndColor;
  final int tickCount;
  final int highlightCount;
  final double innerRadiusRatio;
  final double outerRadiusRatio;

  _CanImageSpinnerPainter({
    required this.rotationAngle,
    required this.primaryColor,
    required this.accentColor,
    required this.accentEndColor,
    required this.tickCount,
    required this.highlightCount,
    required this.innerRadiusRatio,
    required this.outerRadiusRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final outerRadius = radius * outerRadiusRatio;
    final innerRadius = radius * innerRadiusRatio;
    final tickLength = outerRadius - innerRadius;
    final tickWidth = radius * 0.16;
    final cornerRadius = Radius.circular(tickWidth / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    final angleStep = (2 * math.pi) / tickCount;

    final primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Start angle at 9 o'clock (-pi) so the 4 highlight ticks (i=0..3)
    // span from 9 o'clock through 10, 11 to 12 o'clock, perfectly matching the logo!
    const startAngle = -math.pi;

    for (int i = 0; i < tickCount; i++) {
      final tickAngle = startAngle + (i * angleStep);

      canvas.save();
      canvas.rotate(tickAngle);

      Paint paint;
      if (i < highlightCount) {
        // Gradient interpolation across the highlight ticks:
        // i=0 (9 o'clock) is accentEndColor (golden amber)
        // i=3 (12 o'clock) is accentColor (vibrant orange)
        final t = highlightCount > 1 ? i / (highlightCount - 1) : 1.0;
        final tickColor = Color.lerp(accentEndColor, accentColor, t)!;
        paint = Paint()
          ..color = tickColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
      } else {
        paint = primaryPaint;
      }

      // Draw capsule along positive X axis from innerRadius to outerRadius
      final rect = Rect.fromLTWH(
        innerRadius,
        -tickWidth / 2,
        tickLength,
        tickWidth,
      );

      final rrect = RRect.fromRectAndRadius(rect, cornerRadius);
      canvas.drawRRect(rrect, paint);

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CanImageSpinnerPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.accentEndColor != accentEndColor ||
        oldDelegate.tickCount != tickCount ||
        oldDelegate.highlightCount != highlightCount ||
        oldDelegate.innerRadiusRatio != innerRadiusRatio ||
        oldDelegate.outerRadiusRatio != outerRadiusRatio;
  }
}

/// Custom painter for the 4-corner orange camera focus reticle [ ]
class _FocusReticlePainter extends CustomPainter {
  final Color color;

  const _FocusReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = h * 0.22; // Thickness of the corner marks
    final arm = h * 0.38;    // Length of the corner arms
    final r = Radius.circular(stroke * 0.20);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Top-Left corner: ┌
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, arm, stroke), r),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, stroke, arm), r),
      paint,
    );

    // Top-Right corner: ┐
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w - arm, 0, arm, stroke), r),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w - stroke, 0, stroke, arm), r),
      paint,
    );

    // Bottom-Left corner: └
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, h - stroke, arm, stroke), r),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, h - arm, stroke, arm), r),
      paint,
    );

    // Bottom-Right corner: ┘
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w - arm, h - stroke, arm, stroke), r),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w - stroke, h - arm, stroke, arm), r),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusReticlePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// The coded CAN IMAGE brand name widget matching the logo:
/// - 4-corner orange camera focus reticle [ ] on the left
/// - Bold geometric "CAN IMAGE" text in deep navy blue on the right
/// - Built 100% in Flutter code (no image asset used!)
class CanImageBrandName extends StatelessWidget {
  /// Overall height of the brand name mark. Defaults to 20.0.
  final double height;

  /// Optional fontSize (alias for height).
  final double? fontSize;

  /// Color for the 4 orange corner reticle brackets. Defaults to [Font.orangeColor].
  final Color? bracketColor;

  /// Color for the "CAN IMAGE" text. Defaults to [Font.primaryColor].
  final Color? textColor;

  /// Spacing between the focus reticle and the text.
  final double? spacing;

  /// Letter spacing for the text.
  final double? letterSpacing;

  /// Font family. Defaults to 'Roboto'.
  final String fontFamily;

  const CanImageBrandName({
    super.key,
    this.height = 20.0,
    this.fontSize,
    this.bracketColor,
    this.textColor,
    this.spacing,
    this.letterSpacing,
    this.fontFamily = 'Roboto',
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = fontSize ?? height;
    final effectiveTextColor = textColor ?? Font.primaryColor;
    final effectiveBracketColor = bracketColor ?? Font.orangeColor;
    final reticleSize = effectiveHeight * 0.92;
    final effectiveSpacing = spacing ?? (effectiveHeight * 0.36);
    final effectiveLetterSpacing = letterSpacing ?? (effectiveHeight * 0.08);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Camera focus reticle: 4 orange L-corners [ ]
        CustomPaint(
          size: Size(reticleSize, reticleSize),
          painter: _FocusReticlePainter(color: effectiveBracketColor),
        ),
        SizedBox(width: effectiveSpacing),
        // CAN IMAGE text: bold geometric uppercase
        Text(
          'CAN IMAGE',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: effectiveHeight * 0.88,
            fontWeight: FontWeight.w900,
            color: effectiveTextColor,
            letterSpacing: effectiveLetterSpacing,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

/// Backward compatibility alias for [CanImageBrandName].
typedef CanImageBrandText = CanImageBrandName;

/// A complete branded Loader widget containing the animated [CanImageSpinner],
/// optional [CanImageBrandName], and optional status message.
class CanImageLoader extends StatelessWidget {
  /// Diameter of the spinner. Defaults to 54.0.
  final double spinnerSize;

  /// Base color for spinner ticks. Defaults to [Font.primaryColor].
  final Color? primaryColor;

  /// Accent color for spinner ticks. Defaults to [Font.orangeColor].
  final Color? accentColor;

  /// Whether to display the [ CAN IMAGE ] text below the spinner. Default is true.
  final bool showBrand;

  /// Optional message displayed below the loader (e.g., "Please wait...").
  final String? message;

  /// Color for the optional message text.
  final Color? messageColor;

  /// Font size for the optional message. Defaults to 13.0.
  final double messageFontSize;

  /// Spacing between elements.
  final double spacing;

  const CanImageLoader({
    super.key,
    this.spinnerSize = 54.0,
    this.primaryColor,
    this.accentColor,
    this.showBrand = true,
    this.message,
    this.messageColor,
    this.messageFontSize = 13.0,
    this.spacing = 14.0,
  });

  /// Convenient helper to show a modal loading dialog with this loader.
  /// Call [CanImageLoader.hide] to dismiss it.
  static Future<void> show(
    BuildContext context, {
    String? message,
    bool showBrand = true,
    bool barrierDismissible = false,
    Color? backgroundColor,
    double spinnerSize = 54.0,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: barrierDismissible,
          child: Dialog(
            backgroundColor: backgroundColor ?? Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: CanImageLoader(
                spinnerSize: spinnerSize,
                showBrand: showBrand,
                message: message,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper to dismiss a currently open loader dialog.
  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandHeight = spinnerSize * 0.32 < 16.0 ? 16.0 : spinnerSize * 0.32;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CanImageSpinner(
          size: spinnerSize,
          primaryColor: primaryColor,
          accentColor: accentColor,
        ),
        if (showBrand) ...[
          SizedBox(height: spacing),
          CanImageBrandName(
            height: brandHeight,
            textColor: primaryColor,
            bracketColor: accentColor,
          ),
        ],
        if (message != null && message!.isNotEmpty) ...[
          SizedBox(height: showBrand ? 10 : spacing),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: messageFontSize,
              fontWeight: FontWeight.w500,
              color: messageColor ?? Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }
}

/// A convenient wrapper widget that displays a semi-transparent loading
/// overlay with the [CanImageLoader] on top of any child widget.
class CanImageLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final bool showBrand;
  final Color? overlayColor;
  final double spinnerSize;

  const CanImageLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.showBrand = true,
    this.overlayColor,
    this.spinnerSize = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: overlayColor ?? Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CanImageLoader(
                      spinnerSize: spinnerSize,
                      showBrand: showBrand,
                      message: message,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
