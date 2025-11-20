// lib/widgets/day_night_overlay.dart

import 'package:flutter/material.dart';

/// Correct day/night overlay for a world map:
/// - subsolarLon = longitude of the sun (-180 .. +180)
/// - longitudeOffsetDeg = optional small nudge (default = 0)
/// The NIGHT hemisphere is drawn correctly relative to the subsolar point.
class TrueDayNightOverlaySVG extends CustomPainter {
  final Rect viewBox;
  final double subsolarLon;        // -180..+180
  final double longitudeOffsetDeg; // tweak offset if needed

  TrueDayNightOverlaySVG({
    required this.viewBox,
    required this.subsolarLon,
    this.longitudeOffsetDeg = -10.0,   // FIXED: was 90 (wrong)
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = viewBox.width;
    final double height = viewBox.height;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, width, height));

    // 1° of longitude = width/360 px
    final double pxPerDeg = width / 360.0;

    // Apply optional nudge offset
    double effectiveLon = subsolarLon + longitudeOffsetDeg;

    // Normalize to [-180,180]
    effectiveLon = ((effectiveLon + 180) % 360 + 360) % 360 - 180;

    // Convert lon → X position in SVG space
    double subsolarX = (effectiveLon + 180.0) * pxPerDeg;
    subsolarX = subsolarX % width;

    // One full hemisphere = night
    final double nightWidth = width / 2;

    // Smooth twilight fade width
    final double fadeWidth = width * 0.05;

    // NIGHT rectangle (centered opposite sun)
    final Rect nightRect = Rect.fromLTWH(
      subsolarX - nightWidth,
      0,
      nightWidth,
      height,
    );

    const Color solidNight = Color.fromARGB(140, 0, 0, 0);  // slightly softer
    const Color transparent = Color.fromARGB(0, 0, 0, 0);

    final nightPaint = Paint()..color = solidNight;

    // --- Draw main night region ---
    canvas.drawRect(nightRect, nightPaint);

    // --- Right-side twilight (night → day) ---
    final Rect fadeRight = Rect.fromLTWH(nightRect.right, 0, fadeWidth, height);
    canvas.drawRect(
      fadeRight,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [solidNight, transparent],
        ).createShader(fadeRight),
    );

    // --- Left-side twilight (day → night) ---
    final Rect fadeLeft = Rect.fromLTWH(nightRect.left - fadeWidth, 0, fadeWidth, height);
    canvas.drawRect(
      fadeLeft,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [transparent, solidNight],
        ).createShader(fadeLeft),
    );

    // --- Handle wrapping ---
    if (nightRect.left < 0) {
      final Rect wrapNight = nightRect.shift(Offset(width, 0));
      canvas.drawRect(wrapNight, nightPaint);

      final Rect wrapFadeLeft = fadeLeft.shift(Offset(width, 0));
      canvas.drawRect(
        wrapFadeLeft,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [transparent, solidNight],
          ).createShader(wrapFadeLeft),
      );
    }

    if (nightRect.right > width) {
      final Rect wrapNight = nightRect.shift(Offset(-width, 0));
      canvas.drawRect(wrapNight, nightPaint);

      final Rect wrapFadeRight = fadeRight.shift(Offset(-width, 0));
      canvas.drawRect(
        wrapFadeRight,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [solidNight, transparent],
          ).createShader(wrapFadeRight),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(TrueDayNightOverlaySVG old) =>
      old.subsolarLon != subsolarLon ||
          old.viewBox != viewBox ||
          old.longitudeOffsetDeg != longitudeOffsetDeg;
}
