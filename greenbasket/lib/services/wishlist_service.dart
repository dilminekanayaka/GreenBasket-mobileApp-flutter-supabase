import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistService extends ChangeNotifier {
  static final WishlistService _instance = WishlistService._internal();
  factory WishlistService() => _instance;
  WishlistService._internal();

  String? _userId;
  final List<Map<String, dynamic>> _items = [];

  void setUser(String? userId) {
    _userId = userId;
    _items.clear();
    if (_userId != null) {
      _loadFromPrefs();
    } else {
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  String get _storageKey => _userId != null ? 'greenbasket_wishlist_$_userId' : 'greenbasket_wishlist_guest';

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_items));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null) {
      _items.clear();
      _items.addAll(List<Map<String, dynamic>>.from(jsonDecode(json)));
      notifyListeners();
    }
  }

  bool isFavorite(String id) {
    return _items.any((item) => item['id'] == id);
  }

  void toggleFavorite(Map<String, dynamic> product) {
    final index = _items.indexWhere((item) => item['id'] == product['id']);
    if (index >= 0) {
      _items.removeAt(index);
    } else {
      _items.add(product);
    }
    _saveToPrefs();
    notifyListeners();
  }
}
