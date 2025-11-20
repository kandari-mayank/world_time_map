import 'package:flutter/material.dart';
import 'pages/favorites_page.dart';
import 'pages/detail_page.dart';
import 'widgets/world_map_svg.dart';
import 'data/countries.dart';
import 'models/country.dart';

void main() {
  runApp(WorldTimeMapApp());
}

class WorldTimeMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World Time Map',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF1565C0),
        cardColor: Colors.white,
        scaffoldBackgroundColor: Color(0xFFF6F8FA),
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(color: Colors.grey.shade800),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ),

      home: HomeWrapper(),
      routes: {
        '/detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Country;
          return DetailPage(country: args);
        },
        '/favorites': (_) => FavoritesPage(),
      },
    );
  }
}

class HomeWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('World Time Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
          )
        ],
      ),
      body: SafeArea(
        child: WorldMapSvg(assetPath: 'assets/images/world_map.svg'),
      ),
    );
  }
}

class FavoritesPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Favorites')), body: Center(child: Text('Favorites page (implement similarly)')));
  }
}
