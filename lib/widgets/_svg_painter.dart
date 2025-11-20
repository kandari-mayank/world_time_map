// lib/widgets/_svg_painter.dart
import 'package:flutter/material.dart';

/// MapPath holds the parsed Path and svg id/title.
class MapPath {
  final String id;
  final String? title;
  final Path path;
  MapPath({required this.id, required this.path, this.title});
}

/// Painter that draws the base map and paints hover / selected highlights.
class SvgPainter extends CustomPainter {
  final List<MapPath> svgPaths;
  final Rect viewBox;
  final String? highlightId; // tapped (selected) id
  final String? hoverId; // hovered id
  final double highlightProgress; // 0..1 animation progress

  SvgPainter({
    required this.svgPaths,
    required this.viewBox,
    this.highlightId,
    this.hoverId,
    this.highlightProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // compute transform similar to earlier (fit viewBox into size, BoxFit.contain)
    final srcW = viewBox.width;
    final srcH = viewBox.height;
    final dstW = size.width;
    final dstH = size.height;
    final finalScale = (dstW / srcW) < (dstH / srcH) ? dstW / srcW : dstH / srcH;
    final scaledW = srcW * finalScale;
    final scaledH = srcH * finalScale;
    final dx = (dstW - scaledW) / 2.0;
    final dy = (dstH - scaledH) / 2.0;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(finalScale, finalScale);
    canvas.translate(-viewBox.left, -viewBox.top);

    // Base paints
    final baseFill = Paint()..style = PaintingStyle.fill..color = Colors.grey.shade200;
    final baseStroke = Paint()..style = PaintingStyle.stroke..color = Colors.black12..strokeWidth = 0.5;

    // Hover / highlight paints are created and used inline
    for (final mp in svgPaths) {
      // Base drawing
      canvas.drawPath(mp.path, baseFill);
      canvas.drawPath(mp.path, baseStroke);

      // Hover: subtle brighten and blue stroke
      if (mp.id == hoverId) {
        final hoverFill = Paint()..style = PaintingStyle.fill..color = Colors.white.withOpacity(0.06);
        final hoverStroke = Paint()..style = PaintingStyle.stroke..color = Colors.blue.withOpacity(0.22)..strokeWidth = 1.0;
        canvas.drawPath(mp.path, hoverFill);
        canvas.drawPath(mp.path, hoverStroke);
      }

      // Selected: animated orange glow + slightly stronger fill
      if (mp.id == highlightId) {
        final prog = highlightProgress.clamp(0.0, 1.0);
        // soft stroke layers for glow
        for (int i = 0; i < 3; i++) {
          final stroke = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2 + prog * (i + 1) * 1.5
            ..color = Colors.orange.withOpacity(0.12 + prog * 0.25 / (i + 1));
          canvas.drawPath(mp.path, stroke);
        }
        final selFill = Paint()..style = PaintingStyle.fill..color = Colors.orange.withOpacity(0.04 + prog * 0.06);
        canvas.drawPath(mp.path, selFill);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SvgPainter old) {
    return old.svgPaths != svgPaths ||
        old.highlightId != highlightId ||
        old.hoverId != hoverId ||
        old.highlightProgress != highlightProgress ||
        old.viewBox != viewBox;
  }
}
