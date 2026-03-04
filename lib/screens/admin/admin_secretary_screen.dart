import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class AdminSecretaryScreen extends StatefulWidget {
  const AdminSecretaryScreen({super.key});
  @override
  State<AdminSecretaryScreen> createState() => _AdminSecretaryScreenState();
}

class _AdminSecretaryScreenState extends State<AdminSecretaryScreen> {
  List<dynamic> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.query('secretary.getAppointments');
      setState(() => _appointments = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('السكرتارية', style: TextStyle(color: AppColors.text)),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _appointments.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.muted, size: 64),
                  const SizedBox(height: 16),
                  const Text('لا توجد مواعيد مجدولة', style: TextStyle(color: AppColors.muted, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(onPressed: _showAddAppointment, icon: const Icon(Icons.add, color: Colors.black), label: const Text('إضافة موعد')),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (_, i) {
                    final a = _appointments[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.event, color: AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a['title'] ?? '', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                          Text(a['date'] ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ])),
                      ]),
                    );
                  }),
      floatingActionButton: FloatingActionButton(backgroundColor: AppColors.primary, onPressed: _showAddAppointment, child: const Icon(Icons.add, color: Colors.black)),
    );
  }

  void _showAddAppointment() {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('إضافة موعد', style: TextStyle(color: AppColors.text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _tf(titleCtrl, 'عنوان الموعد', Icons.title),
        const SizedBox(height: 10),
        _tf(dateCtrl, 'التاريخ والوقت', Icons.calendar_today),
        const SizedBox(height: 10),
        _tf(notesCtrl, 'ملاحظات', Icons.notes),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: AppColors.muted))),
        ElevatedButton(onPressed: () async {
          try {
            await ApiService.mutate('secretary.createAppointment', input: {'title': titleCtrl.text, 'date': dateCtrl.text, 'notes': notesCtrl.text});
          } catch (_) {}
          if (ctx.mounted) Navigator.pop(ctx);
          _load();
        }, child: const Text('حفظ')),
      ],
    ));
  }

  Widget _tf(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(controller: ctrl, style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.muted), prefixIcon: Icon(icon, color: AppColors.muted), filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)));
  }
}
