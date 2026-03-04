import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});
  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.query('crm.getMessages');
      setState(() => _messages = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('صندوق الرسائل', style: TextStyle(color: AppColors.text)),
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppColors.muted), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _messages.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.inbox_outlined, color: AppColors.muted, size: 64),
                  const SizedBox(height: 16),
                  const Text('صندوق الرسائل فارغ', style: TextStyle(color: AppColors.muted, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('ستظهر هنا رسائل العملاء من واتساب وماسنجر', style: TextStyle(color: AppColors.muted, fontSize: 13), textAlign: TextAlign.center),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    final platformColors = {'whatsapp': Colors.green, 'messenger': Colors.blue, 'sms': Colors.orange};
                    final platform = msg['platform'] ?? 'sms';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 36, height: 36, decoration: BoxDecoration(color: (platformColors[platform] ?? Colors.grey).withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.message, color: platformColors[platform] ?? Colors.grey, size: 18)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(msg['senderName'] ?? 'مجهول', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(platform.toUpperCase(), style: TextStyle(color: platformColors[platform] ?? Colors.grey, fontSize: 11)),
                          ])),
                          Text(msg['createdAt'] ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        ]),
                        const SizedBox(height: 8),
                        Text(msg['content'] ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () {}, icon: const Icon(Icons.reply, size: 16), label: const Text('رد', style: TextStyle(fontSize: 13)))),
                      ]),
                    );
                  }),
    );
  }
}
