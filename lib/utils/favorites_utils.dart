import 'package:shared_preferences/shared_preferences.dart';

const String favoritesKey = 'favorites';

Future<List<String>> getFavorites() async {
  final sp = await SharedPreferences.getInstance();
  return sp.getStringList(favoritesKey) ?? [];
}

Future<void> addFavorite(String code) async {
  final sp = await SharedPreferences.getInstance();
  final list = sp.getStringList(favoritesKey) ?? [];
  if (!list.contains(code)) {
    list.add(code);
    await sp.setStringList(favoritesKey, list);
  }
}

Future<void> removeFavorite(String code) async {
  final sp = await SharedPreferences.getInstance();
  final list = sp.getStringList(favoritesKey) ?? [];
  if (list.contains(code)) {
    list.remove(code);
    await sp.setStringList(favoritesKey, list);
  }
}
