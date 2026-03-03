import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  String? _selectedCategory;
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final productsRes = await ApiService.query('products.getAll');
      final categoriesRes = await ApiService.query('categories.getAll');
      setState(() {
        _products = productsRes['data'] ?? [];
        _categories = categoriesRes['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredProducts {
    return _products.where((p) {
      final matchSearch = _search.isEmpty ||
          (p['name'] ?? '').toLowerCase().contains(_search.toLowerCase());
      final matchCategory = _selectedCategory == null ||
          p['categoryId'].toString() == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    final screens = [
      _buildStore(cart),
      const CartScreen(),
      const ClientOrdersScreen(),
      const ClientProfileScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined), label: 'المتجر'),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('${cart.itemCount}'),
                isLabelVisible: cart.itemCount > 0,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              label: 'السلة',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined), label: 'طلباتي'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'بياناتي'),
          ],
        ),
      ),
    );
  }

  Widget _buildStore(CartProvider cart) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.card,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('ET',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Easy Tech',
                  style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.muted),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  prefixIcon: Icon(Icons.search, color: AppColors.muted),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
              ),
            ),
          ),
        ),

        // Categories
        if (_categories.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return _CategoryChip(
                      label: 'الكل',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    );
                  }
                  final cat = _categories[i - 1];
                  return _CategoryChip(
                    label: cat['name'] ?? '',
                    selected:
                        _selectedCategory == cat['id'].toString(),
                    onTap: () => setState(
                        () => _selectedCategory = cat['id'].toString()),
                  );
                },
              ),
            ),
          ),

        // Products Grid
        if (_loading)
          const SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (_filteredProducts.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text('لا توجد منتجات',
                  style: TextStyle(color: AppColors.muted)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _ProductCard(
                  product: _filteredProducts[i],
                  onAddToCart: (item) {
                    cart.addItem(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إضافة ${item.name} للسلة'),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                          product: _filteredProducts[i]),
                    ),
                  ),
                ),
                childCount: _filteredProducts.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.text,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Function(CartItem) onAddToCart;
  final VoidCallback onTap;

  const _ProductCard(
      {required this.product,
      required this.onAddToCart,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final image = product['mainImageUrl'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: image != null
                    ? Image.network(image,
                        width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${price.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => onAddToCart(CartItem(
                          productId: product['id'],
                          name: product['name'] ?? '',
                          price: price,
                          image: image,
                        )),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.black, size: 18),
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

  Widget _placeholder() {
    return Container(
      color: AppColors.border,
      child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.muted, size: 40)),
    );
  }
}
