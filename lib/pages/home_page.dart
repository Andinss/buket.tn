import 'package:buket_tn/models/bouquet.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/bouquet_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../utils/helpers.dart';
import 'favorite_page.dart';
import 'detail_page.dart';
import 'custom_order_page.dart';
import 'main_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = 'All';
  String searchQuery = '';
  String selectedColor = 'Semua';
  String priceFilter = 'Default'; 
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final PageController _promoController = PageController();
  int _currentPromoPage = 0;

  final List<String> _colorFilters = [
    'Semua',
    'Merah',
    'Pink',
    'Putih',
    'Kuning',
    'Ungu',
    'Biru',
    'Orange',
  ];

  final List<Map<String, dynamic>> _promos = [
    {
      'title': 'Big Sale',
      'subtitle': 'Get Up To 50% Off on\nall flowers this week!',
      'colors': [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
    },
    {
      'title': 'New Arrival',
      'subtitle': 'Fresh flowers just arrived!\nCheck out our collection',
      'colors': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    },
    {
      'title': 'Special Offer',
      'subtitle': 'Buy 2 Get 1 Free\nLimited time only!',
      'colors': [Color(0xFF10B981), Color(0xFF34D399)],
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      // ignore: unused_local_variable
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (mounted) setState(() {});
    });

    Future.delayed(const Duration(seconds: 3), () {
      _autoSlidePromo();
    });
  }

  void _autoSlidePromo() {
    if (!mounted) return;
    
    Future.delayed(const Duration(seconds: 4), () {
      if (_promoController.hasClients) {
        int nextPage = (_currentPromoPage + 1) % _promos.length;
        _promoController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      _autoSlidePromo();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _navigateToCart() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation(initialIndex: 2)),
      (route) => false,
    );
  }

  // TAMBAHAN: Fungsi untuk menampilkan dialog filter harga
  void _showPriceFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sort, color: Color(0xFFFF6B9D)),
            SizedBox(width: 8),
            Text('Urutkan Harga'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Default'),
              value: 'Default',
              groupValue: priceFilter,
              onChanged: (value) {
                setState(() => priceFilter = value!);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFFFF6B9D),
            ),
            RadioListTile<String>(
              title: const Text('Harga: Rp. 0 - Rp. 10.000.000'),
              value: 'Rp. 0 - Rp. 10.000.000',
              groupValue: priceFilter,
              onChanged: (value) {
                setState(() => priceFilter = value!);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFFFF6B9D),
            ),
            RadioListTile<String>(
              title: const Text('Harga: Rp. 10.000.000 - Rp. 0'),
              value: 'Rp. 10.000.000 - Rp. 0',
              groupValue: priceFilter,
              onChanged: (value) {
                setState(() => priceFilter = value!);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFFFF6B9D),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final allBouquets = Provider.of<BouquetProvider>(context).bouquets;
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    String displayName = auth.user?.displayName ?? 'User';
    if (displayName == 'User' && auth.user?.email != null) {
      displayName = auth.user!.email!.split('@').first;
    }

    // Filter berdasarkan pencarian dan warna
    var filteredBouquets = allBouquets.where((b) {
      final matchesSearch = b.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          b.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          b.category.toLowerCase().contains(searchQuery.toLowerCase());
      
      final matchesColor = selectedColor == 'Semua' || 
          b.name.toLowerCase().contains(selectedColor.toLowerCase()) ||
          b.description.toLowerCase().contains(selectedColor.toLowerCase()) ||
          b.details.toLowerCase().contains(selectedColor.toLowerCase());
      
      return matchesSearch && matchesColor;
    }).toList();

    // TAMBAHAN: Sorting berdasarkan harga
    if (priceFilter == 'Rp. 0 - Rp. 10.000.000') {
      filteredBouquets.sort((a, b) => a.price.compareTo(b.price));
    } else if (priceFilter == 'Rp. 10.000.000 - Rp. 0') {
      filteredBouquets.sort((a, b) => b.price.compareTo(a.price));
    }

    final isSeller = auth.user?.role == 'seller';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hello ${displayName.split(' ').first}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritePage())),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFFFFE8F0), shape: BoxShape.circle),
                      child: Stack(
                        children: [
                          const Icon(Icons.favorite, color: Color(0xFFFF6B9D), size: 24),
                          if (favoriteProvider.favoriteIds.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '${favoriteProvider.favoriteIds.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar dengan Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: (value) => setState(() => searchQuery = value),
                              decoration: const InputDecoration(
                                hintText: 'Cari bunga...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          if (searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                                setState(() => searchQuery = '');
                              },
                              child: const Icon(Icons.close, color: Colors.grey, size: 20),
                            )
                          else
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.filter_list, color: Color(0xFFFF6B9D)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) {
                                setState(() => selectedColor = value);
                              },
                              itemBuilder: (context) => _colorFilters.map((color) {
                                return PopupMenuItem<String>(
                                  value: color,
                                  child: Row(
                                    children: [
                                      if (color != 'Semua')
                                        Container(
                                          width: 16,
                                          height: 16,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: _getColorFromName(color),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.grey, width: 1),
                                          ),
                                        ),
                                      Text(color),
                                      if (selectedColor == color)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(Icons.check, size: 16, color: Color(0xFFFF6B9D)),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // TAMBAHAN: Tombol Sort Harga
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showPriceFilterDialog,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: priceFilter != 'Default' ? const Color(0xFFFF6B9D) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Icon(
                        Icons.sort,
                        color: priceFilter != 'Default' ? Colors.white : const Color(0xFFFF6B9D),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            Expanded(
              child: filteredBouquets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('Produk tidak ditemukan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                          const SizedBox(height: 8),
                          Text('Coba cari dengan kata kunci lain', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        // Promo Slider
                        if (searchQuery.isEmpty && selectedColor == 'Semua')
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 140,
                                    child: PageView.builder(
                                      controller: _promoController,
                                      onPageChanged: (index) {
                                        setState(() => _currentPromoPage = index);
                                      },
                                      itemCount: _promos.length,
                                      itemBuilder: (context, index) {
                                        final promo = _promos[index];
                                        return Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 5),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: promo['colors'] as List<Color>,
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      promo['title'] as String,
                                                      style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      promo['subtitle'] as String,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.white,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        'Shop Now',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: (promo['colors'] as List<Color>)[0],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                    
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _promos.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: _currentPromoPage == index ? 24 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _currentPromoPage == index
                                              ? const Color(0xFFFF6B9D)
                                              : Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        if (searchQuery.isEmpty && selectedColor == 'Semua')
                          const SliverToBoxAdapter(child: SizedBox(height: 20)),

                        if (searchQuery.isEmpty && selectedColor == 'Semua')
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildCategoryChip('All'),
                                    _buildCategoryChip('Popular'),
                                    _buildCategoryChip('Recent'),
                                    _buildCategoryChip('Recommended'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),

                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final bouquet = filteredBouquets[index];
                                final isFavorite = favoriteProvider.isFavorite(bouquet.id);
                                return _buildProductCard(context, bouquet, isFavorite, favoriteProvider, cartProvider);
                              },
                              childCount: filteredBouquets.length,
                            ),
                          ),
                        ),
                        
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: !isSeller ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomOrderPage()),
          );
        },
        backgroundColor: const Color(0xFFFF6B9D),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ) : null,
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'merah':
        return Colors.red;
      case 'pink':
        return Colors.pink;
      case 'putih':
        return Colors.white;
      case 'kuning':
        return Colors.yellow;
      case 'ungu':
        return Colors.purple;
      case 'biru':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProductCard(BuildContext context, Bouquet bouquet, bool isFavorite, FavoriteProvider favoriteProvider, CartProvider cartProvider) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(bouquet: bouquet))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  child: Container(
                    width: double.infinity,
                    height: 130,
                    color: const Color(0xFFFFE8F0),
                    child: bouquet.images.isNotEmpty ? buildProductImage(bouquet.images[0]) : const Icon(Icons.image, color: Color(0xFFFF6B9D)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => favoriteProvider.toggleFavorite(bouquet.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: const Color(0xFFFF6B9D),
                      ),
                    ),
                  ),
                ),
                
                if (bouquet.estimationDays > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 10, color: Color(0xFFC78500)),
                          const SizedBox(width: 4),
                          Text(
                            '${bouquet.estimationDays}h',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC78500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bouquet.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bouquet.category,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            formatRupiah(bouquet.price),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF6B9D)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            cartProvider.addItem(bouquet, 1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Added to cart!'),
                                backgroundColor: const Color(0xFFFF6B9D),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                action: SnackBarAction(
                                  label: 'Lihat',
                                  textColor: Colors.white,
                                  onPressed: _navigateToCart,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFFFF6B9D), shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B9D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

extension on User? {
  get role => null;
}