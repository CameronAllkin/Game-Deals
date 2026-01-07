import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CheapSharkAPI.dart';

class Settingsprovider extends ChangeNotifier{
  int _startPageIndex = 1;
  String _displayMode = "simple";
  ThemeMode _themeMode = ThemeMode.system;
  String _seedColour = "Purple";
  static Map<String, Color> colours = {
    "Red": Colors.red,
    "Green": Colors.green,
    "Blue": Colors.blue,
    "Yellow": Colors.yellow,
    "Orange": Colors.orange,
    "Cyan": Colors.cyan,
    "Purple": Colors.purple,
    "Pink": Colors.pink,
    "Brown": Colors.brown,
    "Indigo": Colors.indigo,
    "Teal": Colors.teal,
    "Lime": Colors.lime,
    "Amber": Colors.amber,
    "Grey": Colors.grey,
    "Black": Colors.black,
    "White": Colors.white
  };
  int _apiDelay = CheapSharkAPI.rateLimit;
  List<String> _stores = CheapSharkAPI.stores.keys.toList();

  int get startPageIndex => _startPageIndex;
  String get displayMode => _displayMode;
  ThemeMode get themeMode => _themeMode;
  String get seedColour => _seedColour;
  Color get seedColourC => colours[_seedColour]!;
  int get apiDelay => _apiDelay;
  List<String> get stores => _stores;


  bool _loaded = false;
  bool get loaded => _loaded;


  Settingsprovider(){
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _startPageIndex = prefs.getInt("startPageIndex") ?? 1;
    _displayMode = prefs.getString("displayMode") ?? "simple";
    _themeMode = ThemeMode.values[prefs.getInt("themeMode") ?? 0];
    _seedColour = prefs.getString("seedColour") ?? "Purple";
    _apiDelay = prefs.getInt("apiDelay") ?? CheapSharkAPI.rateLimit;
    _stores = prefs.getStringList("stores") ?? CheapSharkAPI.stores.keys.toList();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setStartPageIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("startPageIndex", index);
    _startPageIndex = index;
    notifyListeners();
  }

  Future<void> setDisplayMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("displayMode", mode);
    _displayMode = mode;
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("themeMode", mode.index);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setColour(String colour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("seedColour", colour);
    _seedColour = colour;
    notifyListeners();
  }

  Future<void> setAPIDelay(int delay) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("apiDelay", delay);
    _apiDelay = delay;
    notifyListeners();
  }

  Future<void> setStores(List<String> selectedStores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("stores", selectedStores);
    _stores = selectedStores;
    notifyListeners();
  }

  Future<void> clearGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("games", []);
  }
}