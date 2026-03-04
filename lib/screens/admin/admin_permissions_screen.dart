import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class AdminPermissionsScreen extends StatefulWidget {
  const AdminPermissionsScreen({super.key});
  @override
  State<AdminPermissionsScreen> createState() => _AdminPermissionsScreenState();
}

class _AdminPermissionsScreenState extends State<AdminPermissionsScreen> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.query('admin.getUsers');
      setState(() => _users = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.card, title: const Text('الصلاحيات', style: TextStyle(color: AppColors.text)), iconTheme: const IconThemeData(color: AppColors.text)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(children: [
              Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('الأدوار المتاحة', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _roleRow('مسؤول (Admin)', 'صلاحيات كاملة على النظام', Colors.red, Icons.admin_panel_settings),
                  const Divider(color: AppColors.border),
                  _roleRow('فني (Technician)', 'إدارة المهام والطلبات المسندة', Colors.orange, Icons.build),
                  const Divider(color: AppColors.border),
                  _roleRow('عميل (Client)', 'تصفح المنتجات وإنشاء الطلبات', Colors.blue, Icons.person),
                ])),
              Expanded(child: _users.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.group_outlined, color: AppColors.muted, size: 64),
                      const SizedBox(height: 16),
                      const Text('لا يوجد مستخدمون مسجلون', style: TextStyle(color: AppColors.muted)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final user = _users[i];
                        final role = user['role'] ?? 'user';
                        final roleColors = {'admin': Colors.red, 'technician': Colors.orange, 'user': Colors.blue};
                        final roleLabels = {'admin': 'مسؤول', 'technician': 'فني', 'user': 'عميل'};
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                          child: Row(children: [
                            CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.2), child: Text((user['name'] ?? 'U')[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(user['name'] ?? '', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                              Text(user['email'] ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            ])),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (roleColors[role] ?? Colors.grey).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                              child: Text(roleLabels[role] ?? role, style: TextStyle(color: roleColors[role] ?? Colors.grey, fontSize: 11, fontWeight: FontWeight.w600))),
                          ]),
                        );
                      })),
            ]),
    );
  }

  Widget _roleRow(String title, String desc, Color color, IconData icon) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
        Text(desc, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      ])),
    ]));
  }
}
