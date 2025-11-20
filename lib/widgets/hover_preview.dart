// lib/widgets/hover_preview.dart
import 'package:flutter/material.dart';
import '../models/country.dart';

class HoverPreview extends StatelessWidget {
  final String svgId;
  final Country? country;
  const HoverPreview({Key? key, required this.svgId, this.country}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = country?.name ?? svgId;
    final capital = country?.capital ?? 'Unknown';
    final flag = country?.flagAsset ?? '';

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white.withOpacity(0.98),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        width: 180,
        child: Row(
          children: [
            flag.isNotEmpty ? Image.asset(flag, width: 36, height: 24, errorBuilder: (_, __, ___) => Icon(Icons.flag, size: 28)) : Icon(Icons.public, size: 28, color: Colors.grey.shade700),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(capital, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
