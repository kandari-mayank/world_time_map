// lib/widgets/world_map_svg.dart
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart' as xml;
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Matrix4;

import '../models/country.dart';
import '../data/countries.dart';
import '../utils/time_utils.dart';
import 'hover_preview.dart';
import 'animated_bottom_sheet_card.dart';
import '_svg_painter.dart'; // MapPath + SvgPainter
import 'day_night_overlay.dart';

class WorldMapSvg extends StatefulWidget {
  final String assetPath;

  const WorldMapSvg({
    Key? key,
    this.assetPath = 'assets/images/world_map.svg',
  }) : super(key: key);

  @override
  State<WorldMapSvg> createState() => _WorldMapSvgState();
}

class _WorldMapSvgState extends State<WorldMapSvg>
    with SingleTickerProviderStateMixin {
  List<MapPath> svgPaths = [];
  Rect svgViewBox = Rect.fromLTWH(0, 0, 1009.6727, 665.96301);
  bool loaded = false;

  String? hoveredId;
  Offset? hoverLocal;
  String? selectedId;
  Country? selectedCountry;

  late AnimationController highlightController;

  // Scroll controller used on mobile horizontal scroll
  final ScrollController _hScrollController = ScrollController();
  bool _didAutoCenterMobile = false;

  @override
  void initState() {
    super.initState();
    highlightController =
    AnimationController(vsync: this, duration: Duration(milliseconds: 600))
      ..addListener(() => setState(() {}));
    _loadSvg();
  }

  @override
  void dispose() {
    highlightController.dispose();
    _hScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSvg() async {
    final raw = await rootBundle.loadString(widget.assetPath);
    final doc = xml.XmlDocument.parse(raw);

    try {
      final svgElem = doc.findElements('svg').first;
      final vb = svgElem.getAttribute('viewBox');

      if (vb != null) {
        final parts = vb.split(RegExp(r'[ ,]+')).map(double.tryParse).toList();
        if (parts.length >= 4 && parts[0] != null) {
          svgViewBox =
              Rect.fromLTWH(parts[0]!, parts[1]!, parts[2]!, parts[3]!);
        }
      } else {
        final wStr = svgElem.getAttribute('width');
        final hStr = svgElem.getAttribute('height');
        if (wStr != null && hStr != null) {
          final w =
              double.tryParse(wStr.replaceAll('px', '')) ?? svgViewBox.width;
          final h =
              double.tryParse(hStr.replaceAll('px', '')) ?? svgViewBox.height;
          svgViewBox = Rect.fromLTWH(0, 0, w, h);
        }
      }
    } catch (_) {}

    final list = <MapPath>[];
    for (final p in doc.findAllElements('path')) {
      final d = p.getAttribute('d');
      if (d == null) continue;

      final id = p.getAttribute('id') ?? '';
      final title =
          p.getAttribute('title') ?? p.getAttribute('data-name') ?? null;

      try {
        final path = parseSvgPathData(d);
        list.add(MapPath(id: id, path: path, title: title));
      } catch (e) {
        debugPrint("Parse error for $id → $e");
      }
    }

    setState(() {
      svgPaths = list;
      loaded = true;
    });
  }

  Country? _countryForSvgId(String id) {
    final byCode =
    countries.where((c) => c.code.toLowerCase() == id.toLowerCase());
    if (byCode.isNotEmpty) return byCode.first;

    final byName =
    countries.where((c) => c.name.toLowerCase() == id.toLowerCase());
    if (byName.isNotEmpty) return byName.first;

    return null;
  }

  void _setSelected(String id) {
    setState(() {
      selectedId = id;
      selectedCountry = _countryForSvgId(id);
    });
    highlightController.forward(from: 0.0);
  }

  void _showBottomSheetFor(String id) {
    final c = _countryForSvgId(id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimatedBottomSheetCard(
        country: c,
        svgId: id,
      ),
    );
  }

  // Compute matrix used to transform SVG coords -> widget coords for the given paintSize
  Matrix4 _svgToWidgetTransform(Size paintSize) {
    final scale = paintSize.width / svgViewBox.width;
    final m = Matrix4.identity();
    m.scale(scale, scale);
    m.translate(-svgViewBox.left, -svgViewBox.top);
    return m;
  }

  // Convert widget-local coords (inside painted child) -> svg coords
  Offset _widgetToSvg(Offset local, Size paintSize) {
    final m = _svgToWidgetTransform(paintSize);
    final inv = Matrix4.tryInvert(m);
    if (inv == null) return Offset.zero;
    final v = inv.transform3(Vector3(local.dx, local.dy, 0));
    return Offset(v.x, v.y);
  }

  List<String> _svgHit(Offset svgPoint) {
    final matches = <String>[];
    for (final mp in svgPaths) {
      try {
        if (mp.path.contains(svgPoint)) matches.add(mp.id);
      } catch (e) {
        // ignore
      }
    }
    return matches;
  }

  bool get _isMobile {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  // Hover handler (only on web/desktop)
  void _handleHover(PointerEvent ev, Size paintSize) {
    if (_isMobile) return;
    final local = ev.localPosition;
    final svgPt = _widgetToSvg(local, paintSize);
    final hits = _svgHit(svgPt);
    setState(() {
      hoveredId = hits.isNotEmpty ? hits.first : null;
      hoverLocal = local;
    });
  }

  void _handleExit(PointerEvent ev) {
    setState(() {
      hoveredId = null;
      hoverLocal = null;
    });
  }

  // Tap handler: localPosition is inside painted child, which is correct for both mobile/web
  void _handleTap(TapDownDetails details, Size paintSize) {
    final local = details.localPosition;
    final svgPt = _widgetToSvg(local, paintSize);
    final hits = _svgHit(svgPt);
    if (hits.isNotEmpty) {
      _setSelected(hits.first);
      _showBottomSheetFor(hits.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return Center(child: CircularProgressIndicator());

    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final maxH = constraints.maxHeight;

      final svgW = svgViewBox.width;
      final svgH = svgViewBox.height;
      final svgAspect = svgW / svgH;

      if (_isMobile) {
        // MOBILE LAYOUT:
        // Map height = device height (paintH = maxH)
        // scale = paintH / svgH
        // paintW = svgW * scale
        final paintH = maxH;
        final scale = paintH / svgH;
        final paintW = svgW * scale;
        final paintSize = Size(paintW, paintH);

        // Prepare painters
        final mapPainter = SvgPainter(
          svgPaths: svgPaths,
          viewBox: svgViewBox,
          highlightId: selectedId,
          hoverId: null, // disable hover on mobile
          highlightProgress: highlightController.value,
        );

        final overlayPainter = TrueDayNightOverlaySVG(
          viewBox: svgViewBox,
          subsolarLon: computeSubsolarLongitude(),
        );

        // Auto-center scroll once (center of map visible)
        if (!_didAutoCenterMobile && _hScrollController.hasClients == false) {
          // Will center after first frame (we need paintW and current viewport width)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_hScrollController.hasClients) return;
            final viewportW = MediaQuery.of(context).size.width;
            final target = (paintW - viewportW) / 2.0;
            if (target > 0) {
              _hScrollController.jumpTo(target);
            }
            _didAutoCenterMobile = true;
          });
        } else if (!_didAutoCenterMobile && _hScrollController.hasClients) {
          // In case we already have a controller
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final viewportW = MediaQuery.of(context).size.width;
            final target = (paintW - viewportW) / 2.0;
            if (target > 0) {
              _hScrollController.jumpTo(target);
            }
            _didAutoCenterMobile = true;
          });
        }

        final child = SizedBox(
          width: paintW,
          height: paintH,
          child: Listener(
            onPointerHover: (ev) => _handleHover(ev, paintSize),
            onPointerDown: _handleExit,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _handleTap(d, paintSize),
              child: Stack(
                children: [
                  CustomPaint(
                    size: paintSize,
                    painter: _SvgPaintWrapper(
                        childPainter: mapPainter, viewBox: svgViewBox),
                  ),
                  CustomPaint(
                    size: paintSize,
                    painter: _OverlayPainterWithTransform(
                        viewBox: svgViewBox, overlayPainter: overlayPainter),
                  ),
                  // no hover preview on mobile
                ],
              ),
            ),
          ),
        );

        return Center(
          child: SingleChildScrollView(
            controller: _hScrollController,
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            child: child,
          ),
        );
      } else {
        // DESKTOP / WEB LAYOUT:
        // Fit to both width & height (BoxFit.contain), centered
        final scale =
        (maxW / svgW < maxH / svgH) ? (maxW / svgW) : (maxH / svgH);
        final paintW = svgW * scale;
        final paintH = svgH * scale;
        final paintSize = Size(paintW, paintH);

        final mapPainter = SvgPainter(
          svgPaths: svgPaths,
          viewBox: svgViewBox,
          highlightId: selectedId,
          hoverId: hoveredId,
          highlightProgress: highlightController.value,
        );

        final overlayPainter = TrueDayNightOverlaySVG(
          viewBox: svgViewBox,
          subsolarLon: computeSubsolarLongitude(),
        );

        final child = SizedBox(
          width: paintW,
          height: paintH,
          child: Listener(
            onPointerHover: (ev) => _handleHover(ev, paintSize),
            onPointerDown: _handleExit,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _handleTap(d, paintSize),
              child: Stack(
                children: [
                  CustomPaint(
                    size: paintSize,
                    painter: _SvgPaintWrapper(
                        childPainter: mapPainter, viewBox: svgViewBox),
                  ),
                  CustomPaint(
                    size: paintSize,
                    painter: _OverlayPainterWithTransform(
                        viewBox: svgViewBox, overlayPainter: overlayPainter),
                  ),
                  if (hoveredId != null && hoverLocal != null)
                    Positioned(
                      left: (hoverLocal!.dx + 12).clamp(8.0, paintW - 200),
                      top: (hoverLocal!.dy + 12).clamp(8.0, paintH - 110),
                      child: HoverPreview(
                        svgId: hoveredId!,
                        country: _countryForSvgId(hoveredId!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        return Center(child: child);
      }
    });
  }
}

/// Wrapper that transforms SVG-space map painting to widget space
class _SvgPaintWrapper extends CustomPainter {
  final CustomPainter childPainter;
  final Rect viewBox;

  _SvgPaintWrapper({
    required this.childPainter,
    required this.viewBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox.width;
    canvas.save();
    canvas.scale(scale, scale);
    childPainter.paint(canvas, Size(viewBox.width, viewBox.height));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SvgPaintWrapper oldDelegate) =>
      oldDelegate.childPainter != childPainter ||
          oldDelegate.viewBox != viewBox;
}

/// Overlay painter wrapper
class _OverlayPainterWithTransform extends CustomPainter {
  final Rect viewBox;
  final CustomPainter overlayPainter;

  _OverlayPainterWithTransform({
    required this.viewBox,
    required this.overlayPainter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox.width;
    canvas.save();
    canvas.scale(scale, scale);
    overlayPainter.paint(canvas, Size(viewBox.width, viewBox.height));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OverlayPainterWithTransform oldDelegate) =>
      true;
}
