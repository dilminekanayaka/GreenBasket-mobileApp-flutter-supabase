import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'product_details_screen.dart';
import '../../services/cart_service.dart';
import '../../services/wishlist_service.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _allProducts = [];
  String _searchQuery = "";
  String _selectedCategory = "All";

  final List<String> _categories = ["All", "Vegetables", "Fruits", "Grains", "Dairy", "Herbs", "Seeds"];

  final _wishlist = WishlistService();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _wishlist.addListener(_onWishlistUpdate);
  }

  @override
  void dispose() {
    _wishlist.removeListener(_onWishlistUpdate);
    super.dispose();
  }

  void _onWishlistUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      // 🔄 FETCH PRODUCTS REGULARLY (Avoid join error if FK is missing)
      final response = await _supabase.from('products').select().order('created_at', ascending: false);
      final rawProducts = List<Map<String, dynamic>>.from(response);
      
      final farmerIds = rawProducts.map((p) => p['farmer_id'] as String).toSet().toList();
      final profilesRes = await _supabase.from('profiles').select('id, full_name').inFilter('id', farmerIds);
      final profilesMap = {for (var p in profilesRes) p['id']: p['full_name']};

      for (var p in rawProducts) {
        final id = p['farmer_id'] as String;
        p['farmer_name'] = profilesMap[id] ?? "Farmer";
      }

      if (!mounted) return;
      setState(() {
        _allProducts = rawProducts;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading products: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((p) {
      final matchesSearch = p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == "All" || p['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
        : RefreshIndicator(
            onRefresh: _loadProducts,
            color: const Color(0xFF2E7D32),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: _allProducts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Text("No products available from farmers yet."),
                    ),
                  )
                : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔍 SEARCH BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSearchBar(),
                  ),
                  const SizedBox(height: 24),
                  
                  // 🏷️ CATEGORIES CHIPS
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),

                  if (_searchQuery.isEmpty && _selectedCategory == "All") ...[
                    // 🔥 FEATURED SECTION
                    _buildSectionHeader("Featured Products"),
                    _buildHorizontalList(_allProducts.take(5).toList()),
                    const SizedBox(height: 24),

                    // 🥬 CATEGORY-WISE SECTIONS
                    ..._categories.where((c) => c != "All").map((category) {
                      final products = _allProducts.where((p) => p['category'] == category).toList();
                      if (products.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: [
                          _buildSectionHeader(category),
                          _buildHorizontalList(products),
                          const SizedBox(height: 24),
                        ],
                      );
                    }),
                  ] else ...[
                    // 🧺 GRID FOR SEARCH/FILTER RESULTS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _searchQuery.isNotEmpty ? "Search Results" : "$_selectedCategory Products",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildProductGrid(_filteredProducts),
                    ),
                  ],
                  
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Search fresh veggies...",
          icon: Icon(Icons.search, color: Color(0xFF4CAF50)),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final category = _categories[index];
              bool isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: isSelected ? [
                      BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                    ] : [],
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
          TextButton(
            onPressed: () => setState(() => _selectedCategory = title == "Featured Products" ? "All" : title),
            child: const Text("See All", style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<Map<String, dynamic>> products) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(width: 170, child: _buildProductCard(products[index])),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 IMAGE
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: product['image_url'] != null
                        ? Image.network(product['image_url'], width: double.infinity, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFFE8F5E9),
                            width: double.infinity,
                            child: const Center(child: Icon(Icons.eco_outlined, size: 50, color: Color(0xFF4CAF50))),
                          ),
                  ),
                  if (product['is_organic'] == true)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(10)),
                        child: const Text("Organic", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _wishlist.toggleFavorite(product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          _wishlist.isFavorite(product['id']) ? Icons.favorite : Icons.favorite_outline, 
                          size: 18, 
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 📝 INFO
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? "Unknown",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "by ${product['farmer_name'] ?? 'Farmer'}",
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rs. ${product['price']}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                          ),
                          Text("/${product['unit'] ?? 'kg'}", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          CartService().addItem(product, 1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("${product['name'] ?? 'Item'} added to cart!"), 
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                          child: const Icon(Icons.add_shopping_cart, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
