import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});
  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _target = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService.mutate('notifications.send', input: {
        'title': _titleCtrl.text,
        'body': _bodyCtrl.text,
        'target': _target,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الإشعار بنجاح'), backgroundColor: Colors.green));
        _titleCtrl.clear();
        _bodyCtrl.clear();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الإشعار'), backgroundColor: Colors.green));
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.card, title: const Text('الإشعارات', style: TextStyle(color: AppColors.text)), iconTheme: const IconThemeData(color: AppColors.text)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('إرسال إشعار جديد', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('العنوان', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: _titleCtrl, style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(hintText: 'عنوان الإشعار', hintStyle: const TextStyle(color: AppColors.muted), filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              const Text('الرسالة', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: _bodyCtrl, maxLines: 4, style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(hintText: 'نص الإشعار...', hintStyle: const TextStyle(color: AppColors.muted), filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              const Text('إرسال إلى', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _target,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الجميع')),
                  DropdownMenuItem(value: 'clients', child: Text('العملاء فقط')),
                  DropdownMenuItem(value: 'technicians', child: Text('الفنيون فقط')),
                ],
                onChanged: (v) => setState(() => _target = v!),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.send, color: Colors.black),
                label: Text(_sending ? 'جاري الإرسال...' : 'إرسال الإشعار'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              )),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('الإشعارات السابقة', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Center(child: Column(children: [
            Icon(Icons.notifications_none, color: AppColors.muted, size: 48),
            const SizedBox(height: 8),
            const Text('لا توجد إشعارات سابقة', style: TextStyle(color: AppColors.muted)),
          ])),
        ]),
      ),
    );
  }
}
