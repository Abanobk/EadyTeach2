import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'admin_orders_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_products_screen.dart';
import 'admin_tasks_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final res = await ApiService.query('admin.getDashboardStats');
      setState(() {
        _stats = res['data'];
        _loadingStats = false;
      });
    } catch (e) {
      setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final screens = [
      _buildDashboard(auth),
      const AdminOrdersScreen(),
      const AdminCustomersScreen(),
      const AdminProductsScreen(),
      const AdminTasksScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined), label: 'الرئيسية'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined), label: 'الطلبات'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outline), label: 'العملاء'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined), label: 'المنتجات'),
            BottomNavigationBarItem(
                icon: Icon(Icons.build_outlined), label: 'المهام'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(AuthProvider auth) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.card,
          floating: true,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('ET',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('لوحة التحكم',
                      style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(auth.user?.name ?? '',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.muted),
              onPressed: _loadStats,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.muted),
              onPressed: () async {
                await auth.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نظرة عامة',
                    style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const SizedBox(height: 16),
                if (_loadingStats)
                  const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(
                        title: 'الطلبات',
                        value: '${_stats?['totalOrders'] ?? 0}',
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFF1565C0),
                      ),
                      _StatCard(
                        title: 'العملاء',
                        value: '${_stats?['totalCustomers'] ?? 0}',
                        icon: Icons.people_outline,
                        color: const Color(0xFF2E7D32),
                      ),
                      _StatCard(
                        title: 'المنتجات',
                        value: '${_stats?['totalProducts'] ?? 0}',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF7B4F1A),
                      ),
                      _StatCard(
                        title: 'المهام',
                        value: '${_stats?['totalTasks'] ?? 0}',
                        icon: Icons.build_outlined,
                        color: const Color(0xFF6A1B9A),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                const Text('الإجراءات السريعة',
                    style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const SizedBox(height: 12),
                _QuickAction(
                  icon: Icons.receipt_long_outlined,
                  title: 'إدارة الطلبات',
                  subtitle: 'عرض وتحديث حالة الطلبات',
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(height: 8),
                _QuickAction(
                  icon: Icons.people_outline,
                  title: 'إدارة العملاء',
                  subtitle: 'عرض وتعديل بيانات العملاء',
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                const SizedBox(height: 8),
                _QuickAction(
                  icon: Icons.inventory_2_outlined,
                  title: 'إدارة المنتجات',
                  subtitle: 'إضافة وتعديل المنتجات',
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                const SizedBox(height: 8),
                _QuickAction(
                  icon: Icons.build_outlined,
                  title: 'إدارة المهام',
                  subtitle: 'توزيع المهام على الفنيين',
                  onTap: () => setState(() => _selectedIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios,
                color: AppColors.muted, size: 14),
          ],
        ),
      ),
    );
  }
}
