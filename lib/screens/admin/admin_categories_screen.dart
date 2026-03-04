import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});
  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<dynamic> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.query('products.getCategories');
      setState(() => _categories = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.card, title: const Text('التصنيفات', style: TextStyle(color: AppColors.text)), iconTheme: const IconThemeData(color: AppColors.text)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _categories.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.category_outlined, color: AppColors.muted, size: 64),
                  const SizedBox(height: 16),
                  const Text('لا توجد تصنيفات بعد', style: TextStyle(color: AppColors.muted, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(onPressed: _showAdd, icon: const Icon(Icons.add, color: Colors.black), label: const Text('إضافة تصنيف')),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.category, color: AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(cat['name'] ?? '', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600))),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                          try { await ApiService.mutate('products.deleteCategory', input: {'id': cat['id']}); } catch (_) {}
                          _load();
                        }),
                      ]),
                    );
                  }),
      floatingActionButton: FloatingActionButton(backgroundColor: AppColors.primary, onPressed: _showAdd, child: const Icon(Icons.add, color: Colors.black)),
    );
  }

  void _showAdd() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('إضافة تصنيف', style: TextStyle(color: AppColors.text)),
      content: TextField(controller: ctrl, style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(hintText: 'اسم التصنيف', hintStyle: const TextStyle(color: AppColors.muted), filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: AppColors.muted))),
        ElevatedButton(onPressed: () async {
          try { await ApiService.mutate('products.createCategory', input: {'name': ctrl.text}); } catch (_) {}
          if (ctx.mounted) Navigator.pop(ctx);
          _load();
        }, child: const Text('إضافة')),
      ],
    ));
  }
}
