import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  String? _userId;
  final List<CartItem> _items = [];

  void setUser(String? userId) {
    _userId = userId;
    _items.clear();
    if (_userId != null) {
      _loadFromPrefs();
    } else {
      notifyListeners();
    }
  }

  List<CartItem> get items => List.unmodifiable(_items);

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  String get _storageKey => _userId != null ? 'greenbasket_cart_$_userId' : 'greenbasket_cart_guest';

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _items.map((item) => item.toMap()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null) {
      final List<dynamic> data = jsonDecode(json);
      _items.clear();
      _items.addAll(data.map((m) => CartItem.fromMap(Map<String, dynamic>.from(m))));
      notifyListeners();
    }
  }

  void addItem(Map<String, dynamic> product, [int quantity = 1]) {
    final index = _items.indexWhere((item) => item.id == product['id']);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: product['id'],
        name: product['name'],
        price: (product['price'] as num).toDouble(),
        quantity: quantity,
        unit: product['unit'] ?? 'kg',
        imageUrl: product['image_url'],
      ));
    }
    _saveToPrefs();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveToPrefs();
    notifyListeners();
  }

  void updateQuantity(String id, int delta) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      _saveToPrefs();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _saveToPrefs();
    notifyListeners();
  }
}

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String unit;
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'unit': unit,
    'image_url': imageUrl,
  };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    id: map['id'],
    name: map['name'],
    price: (map['price'] as num).toDouble(),
    quantity: map['quantity'],
    unit: map['unit'],
    imageUrl: map['image_url'],
  );
}
