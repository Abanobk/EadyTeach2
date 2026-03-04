import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({super.key});
  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  List<dynamic> _tasks = [];
  List<dynamic> _customers = [];
  List<dynamic> _technicians = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.query('tasks.list'),
        ApiService.query('clients.list'),
        ApiService.query('clients.technicians'),
      ]);
      setState(() {
        _tasks = results[0]['data'] ?? [];
        _customers = results[1]['data'] ?? [];
        _technicians = results[2]['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'cancelled': return Colors.red;
      case 'assigned': return AppColors.primary;
      default: return AppColors.muted;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'completed': return 'مكتملة';
      case 'in_progress': return 'جارية';
      case 'cancelled': return 'ملغاة';
      case 'assigned': return 'معينة';
      case 'pending': return 'معلقة';
      default: return status ?? '';
    }
  }

  void _showTaskWizard({Map<String, dynamic>? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TaskWizard(
        task: task,
        customers: _customers,
        technicians: _technicians,
        onSaved: () {
          Navigator.pop(ctx);
          _loadAll();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('إدارة المهام', style: TextStyle(color: AppColors.text)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.muted),
            onPressed: _loadAll,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskWizard(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('مهمة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: AppColors.muted.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      const Text('لا توجد مهام', style: TextStyle(color: AppColors.muted, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('اضغط + لإضافة مهمة جديدة', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (ctx, i) {
                    final task = _tasks[i];
                    final status = task['status'] ?? 'pending';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                            title: Text(
                              task['title'] ?? '',
                              style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (task['customerName'] != null)
                                  Row(children: [
                                    const Icon(Icons.person_outline, size: 13, color: AppColors.muted),
                                    const SizedBox(width: 4),
                                    Text(task['customerName'], style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                  ]),
                                if (task['technicianName'] != null)
                                  Row(children: [
                                    const Icon(Icons.engineering_outlined, size: 13, color: AppColors.muted),
                                    const SizedBox(width: 4),
                                    Text(task['technicianName'], style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                  ]),
                                if (task['scheduledAt'] != null)
                                  Row(children: [
                                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.muted),
                                    const SizedBox(width: 4),
                                    Text(
                                      task['scheduledAt'].toString().substring(0, 10),
                                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                    ),
                                  ]),
                                if (task['estimatedArrivalAt'] != null)
                                  Row(children: [
                                    const Icon(Icons.access_time, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'وصول: ${task['estimatedArrivalAt'].toString().substring(11, 16)}',
                                      style: const TextStyle(color: AppColors.primary, fontSize: 12),
                                    ),
                                  ]),
                                if (task['amount'] != null)
                                  Row(children: [
                                    const Icon(Icons.attach_money, size: 13, color: AppColors.muted),
                                    const SizedBox(width: 4),
                                    Text('${task['amount']} ج.م', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                  ]),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _statusColor(status).withOpacity(0.4)),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showTaskWizard(task: task),
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                  label: const Text('تعديل', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                                ),
                                if (status != 'cancelled')
                                  TextButton.icon(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          backgroundColor: AppColors.card,
                                          title: const Text('تأكيد الإلغاء', style: TextStyle(color: AppColors.text)),
                                          content: const Text('هل تريد إلغاء هذه المهمة؟', style: TextStyle(color: AppColors.muted)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لا')),
                                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('نعم', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ApiService.mutate('tasks.update', input: {'id': task['id'], 'status': 'cancelled'});
                                        _loadAll();
                                      }
                                    },
                                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                                    label: const Text('إلغاء', style: TextStyle(color: Colors.red, fontSize: 13)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TASK WIZARD - نظام 3 خطوات مثل الموقع
// ═══════════════════════════════════════════════════════════
class _TaskWizard extends StatefulWidget {
  final Map<String, dynamic>? task;
  final List<dynamic> customers;
  final List<dynamic> technicians;
  final VoidCallback onSaved;

  const _TaskWizard({
    this.task,
    required this.customers,
    required this.technicians,
    required this.onSaved,
  });

  @override
  State<_TaskWizard> createState() => _TaskWizardState();
}

class _TaskWizardState extends State<_TaskWizard> {
  int _step = 0; // 0, 1, 2
  bool _saving = false;

  // Step 1 - العميل والعنوان
  final _titleCtrl = TextEditingController();
  int? _customerId;

  // Step 2 - التفاصيل
  int? _technicianId;
  DateTime? _scheduledDate;
  TimeOfDay? _estimatedArrivalTime;
  final _amountCtrl = TextEditingController();
  String _collectionType = 'cash';
  String _status = 'assigned';
  final _notesCtrl = TextEditingController();

  // Step 3 - البنود
  final List<TextEditingController> _itemControllers = [TextEditingController()];

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.task!;
      _titleCtrl.text = t['title'] ?? '';
      _customerId = t['customerId'] is int ? t['customerId'] : int.tryParse(t['customerId']?.toString() ?? '');
      _technicianId = t['technicianId'] is int ? t['technicianId'] : int.tryParse(t['technicianId']?.toString() ?? '');
      _status = t['status'] ?? 'assigned';
      _collectionType = t['collectionType'] ?? 'cash';
      _amountCtrl.text = t['amount']?.toString() ?? '';
      _notesCtrl.text = t['notes'] ?? '';
      if (t['scheduledAt'] != null) {
        try { _scheduledDate = DateTime.parse(t['scheduledAt'].toString()); } catch (_) {}
      }
      if (t['estimatedArrivalAt'] != null) {
        try {
          final dt = DateTime.parse(t['estimatedArrivalAt'].toString());
          _estimatedArrivalTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (_) {}
      }
      if (t['items'] != null && (t['items'] as List).isNotEmpty) {
        _itemControllers.clear();
        for (final item in (t['items'] as List)) {
          final desc = item is Map ? (item['description'] ?? '') : item.toString();
          _itemControllers.add(TextEditingController(text: desc));
        }
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _itemControllers) c.dispose();
    super.dispose();
  }

  InputDecoration _dec({String? label, String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عنوان المهمة'), backgroundColor: Colors.red),
      );
      setState(() => _step = 0);
      return;
    }

    setState(() => _saving = true);
    try {
      final items = _itemControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
      String? estimatedArrivalIso;
      if (_estimatedArrivalTime != null) {
        final base = _scheduledDate ?? DateTime.now();
        estimatedArrivalIso = DateTime(base.year, base.month, base.day, _estimatedArrivalTime!.hour, _estimatedArrivalTime!.minute).toIso8601String();
      }

      if (_isEdit) {
        await ApiService.mutate('tasks.update', input: {
          'id': widget.task!['id'],
          'title': _titleCtrl.text.trim(),
          'customerId': _customerId,
          'technicianId': _technicianId,
          'status': _status,
          'scheduledAt': _scheduledDate?.toIso8601String(),
          'estimatedArrivalAt': estimatedArrivalIso,
          'amount': _amountCtrl.text.isNotEmpty ? _amountCtrl.text.trim() : null,
          'collectionType': _collectionType,
          'notes': _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
          'items': items,
        });
      } else {
        await ApiService.mutate('tasks.create', input: {
          'title': _titleCtrl.text.trim(),
          'customerId': _customerId,
          'technicianId': _technicianId,
          'scheduledAt': _scheduledDate?.toIso8601String(),
          'estimatedArrivalAt': estimatedArrivalIso,
          'amount': _amountCtrl.text.isNotEmpty ? _amountCtrl.text.trim() : null,
          'collectionType': _collectionType,
          'notes': _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
          'items': items,
        });
      }
      widget.onSaved();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      _isEdit ? 'تعديل المهمة' : 'مهمة جديدة',
                      style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.muted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Step Indicator - مؤشر الخطوات
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    _StepDot(number: 1, label: 'العميل', active: _step == 0, done: _step > 0),
                    _StepLine(done: _step > 0),
                    _StepDot(number: 2, label: 'التفاصيل', active: _step == 1, done: _step > 1),
                    _StepLine(done: _step > 1),
                    _StepDot(number: 3, label: 'البنود', active: _step == 2, done: false),
                  ],
                ),
              ),

              const Divider(color: AppColors.border, height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    if (_step == 0) _buildStep1(),
                    if (_step == 1) _buildStep2(),
                    if (_step == 2) _buildStep3(),
                  ],
                ),
              ),

              // Bottom buttons
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('السابق'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saving ? null : () {
                          if (_step < 2) {
                            setState(() => _step++);
                          } else {
                            _save();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Text(
                                _step < 2 ? 'التالي ←' : (_isEdit ? 'حفظ التعديلات' : 'إضافة المهمة'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  // ── الخطوة 1: العميل والعنوان ──────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('عنوان المهمة', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(color: AppColors.text),
          decoration: _dec(hint: 'مثال: تركيب كاميرات مراقبة'),
        ),
        const SizedBox(height: 20),
        const Text('اختر العميل', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 8),
        // قائمة العملاء كـ cards قابلة للاختيار
        ...widget.customers.map((c) {
          final id = c['id'] is int ? c['id'] as int : int.tryParse(c['id'].toString());
          final selected = _customerId == id;
          return GestureDetector(
            onTap: () => setState(() => _customerId = id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: selected ? AppColors.primary : AppColors.border,
                    child: Text(
                      (c['name'] ?? '?').toString().isNotEmpty ? (c['name'] ?? '?').toString()[0] : '?',
                      style: TextStyle(color: selected ? Colors.black : AppColors.muted, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name'] ?? '', style: TextStyle(color: selected ? AppColors.primary : AppColors.text, fontWeight: FontWeight.w600)),
                        if (c['phone'] != null)
                          Text(c['phone'], style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          );
        }),
        // بدون عميل
        GestureDetector(
          onTap: () => setState(() => _customerId = null),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _customerId == null ? AppColors.primary.withOpacity(0.1) : AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _customerId == null ? AppColors.primary : AppColors.border,
                width: _customerId == null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _customerId == null ? AppColors.primary : AppColors.border,
                  child: Icon(Icons.person_off_outlined, color: _customerId == null ? Colors.black : AppColors.muted, size: 18),
                ),
                const SizedBox(width: 12),
                Text('بدون عميل', style: TextStyle(color: _customerId == null ? AppColors.primary : AppColors.muted)),
                const Spacer(),
                if (_customerId == null)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── الخطوة 2: التفاصيل ──────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الفني
        const Text('الفني المسؤول', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _technicianId,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.text),
          decoration: _dec(hint: 'اختر الفني'),
          items: [
            const DropdownMenuItem(value: null, child: Text('بدون فني', style: TextStyle(color: AppColors.muted))),
            ...widget.technicians.map((t) => DropdownMenuItem(
              value: t['id'] is int ? t['id'] as int : int.tryParse(t['id'].toString()),
              child: Text(t['name'] ?? '', style: const TextStyle(color: AppColors.text)),
            )),
          ],
          onChanged: (v) => setState(() => _technicianId = v),
        ),
        const SizedBox(height: 16),

        // التاريخ ووقت الوصول
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تاريخ الموعد', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _scheduledDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (c, child) => Theme(
                          data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _scheduledDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.muted),
                          const SizedBox(width: 8),
                          Text(
                            _scheduledDate != null
                                ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                                : 'اختر تاريخ',
                            style: TextStyle(color: _scheduledDate != null ? AppColors.text : AppColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('وقت الوصول', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _estimatedArrivalTime ?? TimeOfDay.now(),
                        builder: (c, child) => Theme(
                          data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _estimatedArrivalTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppColors.muted),
                          const SizedBox(width: 8),
                          Text(
                            _estimatedArrivalTime != null
                                ? _estimatedArrivalTime!.format(context)
                                : 'اختر وقت',
                            style: TextStyle(color: _estimatedArrivalTime != null ? AppColors.text : AppColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // المبلغ وطريقة الدفع
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المبلغ (ج.م)', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.text),
                    decoration: _dec(hint: '0.00'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('طريقة الدفع', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _collectionType,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.text),
                    decoration: _dec(),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('نقداً', style: TextStyle(color: AppColors.text))),
                      DropdownMenuItem(value: 'transfer', child: Text('تحويل بنكي', style: TextStyle(color: AppColors.text))),
                    ],
                    onChanged: (v) => setState(() => _collectionType = v ?? 'cash'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // الحالة (تعديل فقط)
        if (_isEdit) ...[
          const Text('الحالة', style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _status,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.text),
            decoration: _dec(),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('معلقة', style: TextStyle(color: AppColors.text))),
              DropdownMenuItem(value: 'assigned', child: Text('معينة', style: TextStyle(color: AppColors.text))),
              DropdownMenuItem(value: 'in_progress', child: Text('جارية', style: TextStyle(color: AppColors.text))),
              DropdownMenuItem(value: 'completed', child: Text('مكتملة', style: TextStyle(color: AppColors.text))),
              DropdownMenuItem(value: 'cancelled', child: Text('ملغاة', style: TextStyle(color: AppColors.text))),
            ],
            onChanged: (v) => setState(() => _status = v ?? 'assigned'),
          ),
          const SizedBox(height: 16),
        ],

        // الملاحظات
        const Text('ملاحظات', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          style: const TextStyle(color: AppColors.text),
          decoration: _dec(hint: 'أي ملاحظات إضافية...'),
        ),
      ],
    );
  }

  // ── الخطوة 3: البنود ──────────────────────────────────────
  Widget _buildStep3() {
    return StatefulBuilder(
      builder: (ctx, setS) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ملخص المهمة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ملخص المهمة', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 8),
                Text(_titleCtrl.text, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                if (_scheduledDate != null)
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    if (_estimatedArrivalTime != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('وصول: ${_estimatedArrivalTime!.format(ctx)}', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    ],
                  ]),
                if (_amountCtrl.text.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.attach_money, size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text('${_amountCtrl.text} ج.م', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // بنود المهمة
          Row(
            children: [
              const Icon(Icons.checklist_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('بنود المهمة', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() => _itemControllers.add(TextEditingController()));
                  setS(() {});
                },
                icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                label: const Text('إضافة بند', style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('أضف خطوات أو بنود العمل المطلوبة في هذه المهمة', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 12),

          ..._itemControllers.asMap().entries.map((entry) {
            final idx = entry.key;
            final ctrl = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${idx + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      style: const TextStyle(color: AppColors.text),
                      decoration: _dec(hint: 'وصف البند ${idx + 1}...'),
                    ),
                  ),
                  if (_itemControllers.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _itemControllers.removeAt(idx));
                        setS(() {});
                      },
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, color: Colors.red, size: 16),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── مكونات مؤشر الخطوات ──────────────────────────────────────
class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool active;
  final bool done;

  const _StepDot({required this.number, required this.label, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    Color bg = done ? AppColors.primary : (active ? AppColors.primary : AppColors.border);
    Color fg = done ? Colors.black : (active ? Colors.black : AppColors.muted);

    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.black, size: 16)
                : Text('$number', style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: active ? AppColors.primary : AppColors.muted, fontSize: 11)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: done ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
