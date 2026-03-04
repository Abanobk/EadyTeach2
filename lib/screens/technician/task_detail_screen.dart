import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  const TaskDetailScreen({super.key, required this.task});
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? _fullTask;
  List<Map<String, dynamic>> _items = [];
  bool _loadingTask = true;
  bool _paymentDone = false;
  bool _isCompleting = false;
  String _paymentMethod = 'cash';
  final _cashAmountCtrl = TextEditingController();
  final _transferAmountCtrl = TextEditingController();
  File? _transferPhoto;

  @override
  void initState() {
    super.initState();
    _loadFullTask();
  }

  Future<void> _loadFullTask() async {
    setState(() => _loadingTask = true);
    try {
      final taskId = widget.task['id'];
      if (taskId == null) {
        setState(() { _fullTask = widget.task; _loadingTask = false; });
        return;
      }

      // Fetch full task with customer/technician details
      final taskRes = await ApiService.query('tasks.byId', input: {'id': taskId is int ? taskId : int.tryParse(taskId.toString()) ?? taskId});
      final itemsRes = await ApiService.query('tasks.items', input: {'taskId': taskId is int ? taskId : int.tryParse(taskId.toString()) ?? taskId});

      final rawTask = taskRes['data'];
      final rawItems = itemsRes['data'];

      // Build full task merging byId data with list data (byId has customer/technician objects)
      Map<String, dynamic> fullTask = {};
      if (rawTask is Map) {
        fullTask = Map<String, dynamic>.from(rawTask);
      } else {
        fullTask = Map<String, dynamic>.from(widget.task);
      }

      // Also merge in list-level fields if not already present (customerName, customerPhone, etc.)
      for (final key in widget.task.keys) {
        if (!fullTask.containsKey(key) || fullTask[key] == null) {
          fullTask[key] = widget.task[key];
        }
      }

      List<Map<String, dynamic>> items = [];
      if (rawItems is List) {
        items = rawItems.map<Map<String, dynamic>>((item) => {
          'id': item['id'],
          'text': item['description']?.toString() ?? '',
          'done': item['isCompleted'] == true,
          'photos': <File>[],
        }).toList();
      }

      setState(() {
        _fullTask = fullTask;
        _items = items;
        _loadingTask = false;
      });
    } catch (e) {
      // Fallback to widget.task data
      setState(() { _fullTask = Map<String, dynamic>.from(widget.task); _loadingTask = false; });
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Add country code if not present
    final withCode = clean.startsWith('20') ? clean : '20$clean';
    final uri = Uri.parse('https://wa.me/$withCode');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://maps.google.com/?q=$encoded');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pickPhoto(int itemIndex, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => (_items[itemIndex]['photos'] as List<File>).add(File(picked.path)));
  }

  void _showPhotoSourceDialog(int itemIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary), title: const Text('التقاط صورة', style: TextStyle(color: AppColors.text)), onTap: () { Navigator.pop(context); _pickPhoto(itemIndex, ImageSource.camera); }),
        ListTile(leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary), title: const Text('اختيار من المعرض', style: TextStyle(color: AppColors.text)), onTap: () { Navigator.pop(context); _pickPhoto(itemIndex, ImageSource.gallery); }),
        const SizedBox(height: 8),
      ])),
    );
  }

  Future<void> _pickTransferPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) setState(() => _transferPhoto = File(picked.path));
  }

  void _showPaymentSheet() {
    final amount = _fullTask?['amount']?.toString() ?? '0';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('تحصيل المبلغ', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('المبلغ المطلوب: $amount ج.م', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => setS(() => _paymentMethod = 'cash'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _paymentMethod == 'cash' ? AppColors.primary.withOpacity(0.15) : AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _paymentMethod == 'cash' ? AppColors.primary : AppColors.border, width: _paymentMethod == 'cash' ? 1.5 : 1),
                  ),
                  child: Column(children: [
                    Icon(Icons.payments_outlined, color: _paymentMethod == 'cash' ? AppColors.primary : AppColors.muted, size: 24),
                    const SizedBox(height: 4),
                    Text('نقداً', style: TextStyle(color: _paymentMethod == 'cash' ? AppColors.primary : AppColors.muted, fontWeight: FontWeight.bold)),
                  ]),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => setS(() => _paymentMethod = 'transfer'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _paymentMethod == 'transfer' ? AppColors.primary.withOpacity(0.15) : AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _paymentMethod == 'transfer' ? AppColors.primary : AppColors.border, width: _paymentMethod == 'transfer' ? 1.5 : 1),
                  ),
                  child: Column(children: [
                    Icon(Icons.account_balance_outlined, color: _paymentMethod == 'transfer' ? AppColors.primary : AppColors.muted, size: 24),
                    const SizedBox(height: 4),
                    Text('تحويل', style: TextStyle(color: _paymentMethod == 'transfer' ? AppColors.primary : AppColors.muted, fontWeight: FontWeight.bold)),
                  ]),
                ),
              )),
            ]),
            const SizedBox(height: 16),
            if (_paymentMethod == 'cash') ...[
              TextField(
                controller: _cashAmountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'المبلغ المستلم', labelStyle: const TextStyle(color: AppColors.muted),
                  suffixText: 'ج.م', suffixStyle: const TextStyle(color: AppColors.muted),
                  filled: true, fillColor: AppColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () {
                  if (_cashAmountCtrl.text.trim().isEmpty) return;
                  setState(() => _paymentDone = true);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل التحصيل النقدي ✓'), backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('تحصيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              )),
            ] else ...[
              GestureDetector(
                onTap: () async { await _pickTransferPhoto(); setS(() {}); },
                child: Container(
                  height: 140, width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _transferPhoto == null ? Colors.red.withOpacity(0.5) : Colors.green, width: 1.5)),
                  child: _transferPhoto == null
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 32),
                          SizedBox(height: 8),
                          Text('التقط صورة إيصال التحويل (إلزامي)', style: TextStyle(color: AppColors.muted, fontSize: 13), textAlign: TextAlign.center),
                        ])
                      : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_transferPhoto!, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _transferAmountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'المبلغ المحوّل', labelStyle: const TextStyle(color: AppColors.muted),
                  suffixText: 'ج.م', suffixStyle: const TextStyle(color: AppColors.muted),
                  filled: true, fillColor: AppColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _transferPhoto == null || _transferAmountCtrl.text.trim().isEmpty ? null : () {
                  setState(() => _paymentDone = true);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل التحويل ✓'), backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, disabledBackgroundColor: AppColors.border, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('تحصيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              )),
            ],
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  Future<void> _completeTask() async {
    setState(() => _isCompleting = true);
    try {
      await ApiService.mutate('tasks.update', input: {'id': _fullTask!['id'], 'status': 'completed', 'collectionType': _paymentMethod, 'collectionStatus': 'collected'});
      setState(() { _fullTask!['status'] = 'completed'; _isCompleting = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنهاء المهمة بنجاح ✓'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } catch (_) {
      setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingTask) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(backgroundColor: AppColors.card, title: const Text('تفاصيل المهمة', style: TextStyle(color: AppColors.text)), iconTheme: const IconThemeData(color: AppColors.text)),
          body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }

    final task = _fullTask ?? widget.task;

    // Extract customer info - from nested object OR from flat fields
    final customerObj = task['customer'];
    final clientName = (customerObj is Map ? customerObj['name'] : null)?.toString()
        ?? task['customerName']?.toString()
        ?? 'غير محدد';
    final phone = (customerObj is Map ? customerObj['phone'] : null)?.toString()
        ?? task['customerPhone']?.toString()
        ?? '';
    final address = (customerObj is Map ? customerObj['address'] : null)?.toString()
        ?? task['customerAddress']?.toString()
        ?? task['address']?.toString()
        ?? '';

    // Extract technician info
    final technicianObj = task['technician'];
    final techName = (technicianObj is Map ? technicianObj['name'] : null)?.toString()
        ?? task['technicianName']?.toString()
        ?? '';

    final amount = task['amount']?.toString() ?? '0';
    final status = task['status']?.toString() ?? 'pending';
    final title = task['title']?.toString() ?? 'مهمة';
    final notes = task['notes']?.toString() ?? '';

    // Format estimated arrival time
    String? estimatedArrival;
    final arrivalRaw = task['estimatedArrivalAt'];
    if (arrivalRaw != null) {
      try {
        final dt = DateTime.parse(arrivalRaw.toString()).toLocal();
        estimatedArrival = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        estimatedArrival = arrivalRaw.toString().length > 15
            ? arrivalRaw.toString().substring(11, 16)
            : arrivalRaw.toString();
      }
    } else {
      // Calculate estimated arrival as 20 min from now
      final now = DateTime.now();
      final arrival = now.add(const Duration(minutes: 20));
      estimatedArrival = '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
    }

    // Format scheduled date
    String? scheduledDate;
    final scheduledRaw = task['scheduledAt'];
    if (scheduledRaw != null) {
      try {
        final dt = DateTime.parse(scheduledRaw.toString()).toLocal();
        scheduledDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        scheduledDate = scheduledRaw.toString().length >= 10
            ? scheduledRaw.toString().substring(0, 10)
            : scheduledRaw.toString();
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          title: Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
          iconTheme: const IconThemeData(color: AppColors.text),
          actions: [
            Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadFullTask,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── بيانات العميل ──
              _sectionTitle(Icons.person_outline, 'بيانات العميل'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: _cardDecor(),
                child: Column(children: [
                  Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.person, color: AppColors.primary, size: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(clientName, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
                      if (techName.isNotEmpty) Text('الفني: $techName', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      if (scheduledDate != null) Text('الموعد: $scheduledDate', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ])),
                  ]),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.phone_outlined, color: AppColors.muted, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(phone, style: const TextStyle(color: AppColors.text, fontSize: 14))),
                      GestureDetector(
                        onTap: () => _callPhone(phone),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.call, color: Colors.green, size: 15), SizedBox(width: 4), Text('اتصال', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))])),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _openWhatsApp(phone),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.chat, color: Color(0xFF25D366), size: 15), SizedBox(width: 4), Text('واتساب', style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold, fontSize: 12))])),
                      ),
                    ]),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text('لم يُسجَّل رقم هاتف للعميل', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ]),
              ),
              const SizedBox(height: 12),

              // ── العنوان والموقع ──
              _sectionTitle(Icons.location_on_outlined, 'الموقع'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: _cardDecor(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.home_outlined, color: AppColors.muted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(address.isNotEmpty ? address : 'لم يُحدد العنوان', style: TextStyle(color: address.isNotEmpty ? AppColors.text : AppColors.muted, fontSize: 14))),
                  ]),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(
                      onPressed: () => _openMaps(address),
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('توجيه للوجهة'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    )),
                  ],
                ]),
              ),
              const SizedBox(height: 12),

              // ── المبلغ ووقت الوصول ──
              Row(children: [
                Expanded(child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecor(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.attach_money, color: AppColors.primary, size: 18), SizedBox(width: 6), Text('المبلغ', style: TextStyle(color: AppColors.muted, fontSize: 12))]),
                    const SizedBox(height: 6),
                    Text('$amount ج.م', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                )),
                const SizedBox(width: 12),
                Expanded(child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecor(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.access_time, color: Colors.blue, size: 18), SizedBox(width: 6), Text('وقت الوصول', style: TextStyle(color: AppColors.muted, fontSize: 12))]),
                    const SizedBox(height: 6),
                    Text(estimatedArrival ?? '--:--', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(task['estimatedArrivalAt'] != null ? 'المحدد' : 'تقريباً', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                  ]),
                )),
              ]),
              const SizedBox(height: 12),

              // ── الملاحظات ──
              if (notes.isNotEmpty) ...[
                _sectionTitle(Icons.notes_outlined, 'ملاحظات'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecor(),
                  child: Text(notes, style: const TextStyle(color: AppColors.text, fontSize: 14, height: 1.5)),
                ),
                const SizedBox(height: 12),
              ],

              // ── بنود المهام ──
              _sectionTitle(Icons.checklist_outlined, 'بنود المهمة'),
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecor(),
                  child: const Text('لا توجد بنود محددة لهذه المهمة', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                )
              else
                ..._items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final photos = item['photos'] as List<File>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: _cardDecor(),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        GestureDetector(
                          onTap: () => _showPhotoSourceDialog(i),
                          child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 18)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item['text'], style: TextStyle(color: item['done'] ? AppColors.muted : AppColors.text, fontSize: 14, decoration: item['done'] ? TextDecoration.lineThrough : null))),
                        GestureDetector(
                          onTap: () => setState(() => _items[i]['done'] = !item['done']),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(color: item['done'] ? Colors.green.withOpacity(0.2) : AppColors.bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: item['done'] ? Colors.green : AppColors.border, width: 1.5)),
                            child: item['done'] ? const Icon(Icons.check, color: Colors.green, size: 18) : null,
                          ),
                        ),
                      ]),
                      if (photos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(height: 64, child: ListView(scrollDirection: Axis.horizontal, children: photos.map((f) => Container(margin: const EdgeInsets.only(left: 6), width: 64, height: 64, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(f, fit: BoxFit.cover)))).toList())),
                      ],
                    ]),
                  );
                }).toList(),
              const SizedBox(height: 16),

              // ── زر التحصيل ──
              if (!_paymentDone && status != 'completed') ...[
                _sectionTitle(Icons.payments_outlined, 'التحصيل'),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: _showPaymentSheet,
                  icon: const Icon(Icons.payments_outlined, color: Colors.black),
                  label: Text('تحصيل $amount ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
                const SizedBox(height: 16),
              ],

              // ── زر إنهاء المهمة ──
              if (_paymentDone && status != 'completed') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
                  child: const Row(children: [Icon(Icons.check_circle_outline, color: Colors.green, size: 20), SizedBox(width: 8), Text('تم تسجيل التحصيل بنجاح', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))]),
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: _isCompleting ? null : _completeTask,
                  icon: _isCompleting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.task_alt, color: Colors.white),
                  label: const Text('إنهاء المهمة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
                const SizedBox(height: 16),
              ],

              if (status == 'completed')
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.task_alt, color: Colors.green, size: 22), SizedBox(width: 8), Text('تم إنجاز هذه المهمة', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15))]),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border));

  Widget _sectionTitle(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [Icon(icon, color: AppColors.primary, size: 18), const SizedBox(width: 6), Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14))]),
  );

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFD4920A);
      case 'assigned': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return AppColors.muted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'جديدة';
      case 'assigned': return 'معينة';
      case 'in_progress': return 'جاري التنفيذ';
      case 'completed': return 'مكتملة';
      case 'cancelled': return 'ملغاة';
      default: return status;
    }
  }

  @override
  void dispose() {
    _cashAmountCtrl.dispose();
    _transferAmountCtrl.dispose();
    super.dispose();
  }
}
