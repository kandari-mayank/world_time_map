import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/countries.dart';
import '../models/country.dart';
import '../utils/favorites_utils.dart';
import '../pages/detail_page.dart';

DateTime localTime(double offset) {
  final now = DateTime.now().toUtc();
  final hrs = offset.truncate();
  final mins = ((offset - hrs) * 60).round();
  return now.add(Duration(hours: hrs, minutes: mins));
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Country> favoriteCountries = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    loadFavorites();

    // Update times every second
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadFavorites() async {
    final favCodes = await getFavorites();
    final list = <Country>[];

    for (var code in favCodes) {
      final match = countries.firstWhere(
            (c) => c.code.toLowerCase() == code.toLowerCase(),
        orElse: () => Country(
            code: code,
            name: code,
            capital: "Unknown",
            flagAsset: "",
            utcOffset: 0),
      );
      list.add(match);
    }

    setState(() => favoriteCountries = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favorites"),
      ),
      body: favoriteCountries.isEmpty
          ? Center(
          child: Text(
            "No favorites added yet!",
            style: TextStyle(fontSize: 18),
          ))
          : ListView.builder(
        itemCount: favoriteCountries.length,
        itemBuilder: (context, index) {
          final c = favoriteCountries[index];
          final time = localTime(c.utcOffset);
          final timeStr = DateFormat("HH:mm:ss").format(time);

          return Dismissible(
            key: Key(c.code),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              padding: EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) async {
              await removeFavorite(c.code);
              loadFavorites();
            },
            child: ListTile(
              leading: c.flagAsset.isNotEmpty
                  ? Image.asset(c.flagAsset, width: 40)
                  : Icon(Icons.flag),
              title: Text("${c.name}"),
              subtitle: Text("Time: $timeStr"),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, "/detail",
                    arguments: c);
              },
            ),
          );
        },
      ),
    );
  }
}
