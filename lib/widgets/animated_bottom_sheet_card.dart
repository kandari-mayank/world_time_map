// lib/widgets/animated_bottom_sheet_card.dart
import 'package:flutter/material.dart';
import '../models/country.dart';
import '../utils/favorites_utils.dart';

class AnimatedBottomSheetCard extends StatefulWidget {
  final Country? country;
  final String svgId;
  const AnimatedBottomSheetCard({Key? key, required this.country, required this.svgId}) : super(key: key);

  @override
  _AnimatedBottomSheetCardState createState() => _AnimatedBottomSheetCardState();
}

class _AnimatedBottomSheetCardState extends State<AnimatedBottomSheetCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: 320));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.country;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0,4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    c != null && c.flagAsset.isNotEmpty
                        ? Image.asset(c.flagAsset, width: 56, errorBuilder: (_, __, ___) => Icon(Icons.flag))
                        : Icon(Icons.public, size: 44),
                    SizedBox(width: 12),
                    Expanded(child: Text(c?.name ?? widget.svgId, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                SizedBox(height: 8),
                if (c != null) ...[
                  Row(children: [Text('Capital:', style: TextStyle(color: Colors.grey)), SizedBox(width: 8), Text(c.capital)]),
                  SizedBox(height: 12),
                ],
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.access_time),
                      label: Text('Show Time'),
                      onPressed: () {
                        Navigator.pop(context);
                        if (c != null) Navigator.pushNamed(context, '/detail', arguments: c);
                      },
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.favorite_border),
                      label: Text('Add Favorite'),
                      onPressed: () async {
                        if (c != null) {
                          await addFavorite(c.code);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.name} added to favorites')));
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
