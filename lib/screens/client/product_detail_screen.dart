import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0;
    final image = p['mainImageUrl'] as String?;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(p['name'] ?? ''),
          backgroundColor: AppColors.card,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              SizedBox(
                height: 280,
                width: double.infinity,
                child: image != null
                    ? Image.network(image, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] ?? '',
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${price.toStringAsFixed(2)} ج.م',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    if (p['description'] != null)
                      Text(p['description'],
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 14, height: 1.6)),
                    const SizedBox(height: 24),
                    // Quantity
                    Row(
                      children: [
                        const Text('الكمية:',
                            style: TextStyle(
                                color: AppColors.text, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove,
                                    color: AppColors.text, size: 18),
                                onPressed: () {
                                  if (_qty > 1) setState(() => _qty--);
                                },
                              ),
                              Text('$_qty',
                                  style: const TextStyle(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add,
                                    color: AppColors.text, size: 18),
                                onPressed: () => setState(() => _qty++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<CartProvider>().addItem(CartItem(
                                productId: p['id'],
                                name: p['name'] ?? '',
                                price: price,
                                image: image,
                                quantity: _qty,
                              ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تمت الإضافة للسلة'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.shopping_cart_outlined,
                            color: Colors.black),
                        label: const Text('أضف للسلة'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.border,
      child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.muted, size: 64)),
    );
  }
}
