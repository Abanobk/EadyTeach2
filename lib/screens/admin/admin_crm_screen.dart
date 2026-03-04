import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class AdminCrmScreen extends StatefulWidget {
  const AdminCrmScreen({super.key});
  @override
  State<AdminCrmScreen> createState() => _AdminCrmScreenState();
}

class _AdminCrmScreenState extends State<AdminCrmScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _leads = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeads();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeads() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.query('crm.getLeads');
      setState(() => _leads = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('نظام CRM', style: TextStyle(color: AppColors.text)),
        iconTheme: const IconThemeData(color: AppColors.text),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          tabs: const [Tab(text: 'العملاء المحتملون'), Tab(text: 'المحادثات')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLeads(), _buildConversations()],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showAddLead,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildLeads() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_leads.isEmpty) return _empty(Icons.people_outline, 'لا يوجد عملاء محتملون');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leads.length,
      itemBuilder: (_, i) {
        final lead = _leads[i];
        final statusMap = {'new': 'جديد', 'contacted': 'تم التواصل', 'converted': 'تحول لعميل', 'lost': 'مفقود'};
        final colorMap = {'new': Colors.blue, 'contacted': Colors.orange, 'converted': Colors.green, 'lost': Colors.red};
        final status = lead['status'] ?? 'new';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lead['name'] ?? '', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
              Text(lead['phone'] ?? lead['email'] ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: (colorMap[status] ?? Colors.grey).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(statusMap[status] ?? status, style: TextStyle(color: colorMap[status] ?? Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildConversations() {
    return _empty(Icons.chat_bubble_outline, 'صندوق المحادثات\nسيتم ربطه مع واتساب وماسنجر');
  }

  Widget _empty(IconData icon, String text) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: AppColors.muted, size: 64),
      const SizedBox(height: 16),
      Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 16), textAlign: TextAlign.center),
    ]));
  }

  void _showAddLead() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('إضافة عميل محتمل', style: TextStyle(color: AppColors.text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _tf(nameCtrl, 'الاسم', Icons.person_outline),
        const SizedBox(height: 12),
        _tf(phoneCtrl, 'رقم الهاتف', Icons.phone_outlined),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: AppColors.muted))),
        ElevatedButton(
          onPressed: () async {
            try {
              await ApiService.mutate('crm.createLead', input: {'name': nameCtrl.text, 'phone': phoneCtrl.text});
              if (ctx.mounted) Navigator.pop(ctx);
              _loadLeads();
            } catch (_) {
              if (ctx.mounted) Navigator.pop(ctx);
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    ));
  }

  Widget _tf(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: Icon(icon, color: AppColors.muted),
        filled: true, fillColor: AppColors.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}
