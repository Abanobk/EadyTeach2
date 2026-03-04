import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class AdminSecretaryScreen extends StatefulWidget {
  const AdminSecretaryScreen({super.key});
  @override
  State<AdminSecretaryScreen> createState() => _AdminSecretaryScreenState();
}

class _AdminSecretaryScreenState extends State<AdminSecretaryScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  final List<Map<String, dynamic>> _appointments = [];

  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.event_available_outlined, 'label': 'حجز موعد', 'color': Colors.blue, 'type': 'booking'},
    {'icon': Icons.phone_callback_outlined, 'label': 'مكالمة', 'color': Colors.green, 'type': 'call'},
    {'icon': Icons.home_repair_service_outlined, 'label': 'زيارة منزلية', 'color': Colors.orange, 'type': 'visit'},
    {'icon': Icons.engineering_outlined, 'label': 'صيانة', 'color': Colors.purple, 'type': 'maintenance'},
    {'icon': Icons.receipt_long_outlined, 'label': 'متابعة طلب', 'color': Colors.teal, 'type': 'followup'},
    {'icon': Icons.meeting_room_outlined, 'label': 'اجتماع', 'color': Colors.red, 'type': 'meeting'},
  ];

  List<Map<String, dynamic>> get _todayAppointments {
    return _appointments.where((a) {
      final d = a['date'] as DateTime;
      return d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
    }).toList()..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  bool _hasAppointments(DateTime day) {
    return _appointments.any((a) {
      final d = a['date'] as DateTime;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    });
  }

  void _showAddAppointmentDialog({String? presetType}) {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selDT = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 9, 0);
    String selType = presetType ?? 'booking';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('موعد جديد', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                const Text('نوع الموعد', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _quickActions.map((qa) {
                      final isSel = selType == qa['type'];
                      return GestureDetector(
                        onTap: () {
                          setS(() => selType = qa['type']);
                          if (titleCtrl.text.isEmpty) titleCtrl.text = qa['label'];
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? (qa['color'] as Color).withOpacity(0.2) : AppColors.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? qa['color'] as Color : AppColors.border, width: isSel ? 1.5 : 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(qa['icon'] as IconData, color: isSel ? qa['color'] as Color : AppColors.muted, size: 16),
                              const SizedBox(width: 6),
                              Text(qa['label'] as String, style: TextStyle(color: isSel ? qa['color'] as Color : AppColors.muted, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'عنوان الموعد',
                    labelStyle: const TextStyle(color: AppColors.muted),
                    filled: true, fillColor: AppColors.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx2,
                            initialDate: selDT,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (c, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)), child: child!),
                          );
                          if (picked != null) setS(() => selDT = DateTime(picked.year, picked.month, picked.day, selDT.hour, selDT.minute));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text('${selDT.day}/${selDT.month}/${selDT.year}', style: const TextStyle(color: AppColors.text, fontSize: 13)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx2,
                            initialTime: TimeOfDay(hour: selDT.hour, minute: selDT.minute),
                            builder: (c, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)), child: child!),
                          );
                          if (picked != null) setS(() => selDT = DateTime(selDT.year, selDT.month, selDT.day, picked.hour, picked.minute));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            const Icon(Icons.access_time, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text('${selDT.hour.toString().padLeft(2, '0')}:${selDT.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: AppColors.text, fontSize: 13)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  style: const TextStyle(color: AppColors.text),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    labelStyle: const TextStyle(color: AppColors.muted),
                    filled: true, fillColor: AppColors.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final action = _quickActions.firstWhere((q) => q['type'] == selType);
                      setState(() {
                        _appointments.add({
                          'title': titleCtrl.text.trim(),
                          'notes': notesCtrl.text.trim(),
                          'date': selDT,
                          'type': selType,
                          'color': action['color'],
                          'icon': action['icon'],
                        });
                        _selectedDate = DateTime(selDT.year, selDT.month, selDT.day);
                        _focusedMonth = DateTime(selDT.year, selDT.month);
                      });
                      Navigator.pop(ctx2);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('حفظ الموعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('السكرتارية', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: () => _showAddAppointmentDialog(), tooltip: 'موعد جديد'),
        ],
      ),
      body: Column(
        children: [
          // ── الكالندر ──
          Container(
            color: AppColors.card,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.text), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1))),
                    Text(_monthName(_focusedMonth.month) + ' ${_focusedMonth.year}', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.text), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1))),
                  ],
                ),
                Row(
                  children: ['أح', 'إث', 'ثل', 'أر', 'خم', 'جم', 'سب'].map((d) =>
                    Expanded(child: Center(child: Text(d, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600))))
                  ).toList(),
                ),
                const SizedBox(height: 4),
                _buildCalendarGrid(),
              ],
            ),
          ),
          // ── الإجراءات السريعة ──
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('إجراء سريع', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _quickActions.map((qa) => GestureDetector(
                      onTap: () => _showAddAppointmentDialog(presetType: qa['type']),
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 38, height: 38, decoration: BoxDecoration(color: (qa['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(qa['icon'] as IconData, color: qa['color'] as Color, size: 20)),
                            const SizedBox(height: 4),
                            Text(qa['label'] as String, style: const TextStyle(color: AppColors.text, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          // ── مواعيد اليوم ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.today_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('مواعيد ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      Text('${_todayAppointments.length} موعد', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: _todayAppointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available_outlined, size: 48, color: AppColors.muted.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              const Text('لا توجد مواعيد في هذا اليوم', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => _showAddAppointmentDialog(),
                                icon: const Icon(Icons.add, color: AppColors.primary, size: 16),
                                label: const Text('إضافة موعد', style: TextStyle(color: AppColors.primary)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _todayAppointments.length,
                          itemBuilder: (ctx, i) {
                            final apt = _todayAppointments[i];
                            final dt = apt['date'] as DateTime;
                            return Dismissible(
                              key: Key('${apt['title']}_${dt.millisecondsSinceEpoch}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                              onDismissed: (_) => setState(() => _appointments.remove(apt)),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(width: 42, height: 42, decoration: BoxDecoration(color: (apt['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(apt['icon'] as IconData, color: apt['color'] as Color, size: 22)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(apt['title'], style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
                                          if ((apt['notes'] as String).isNotEmpty)
                                            Text(apt['notes'], style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                                      child: Text('${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAppointmentDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final totalCells = startWeekday + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final dayIndex = row * 7 + col - startWeekday + 1;
            if (dayIndex < 1 || dayIndex > lastDay.day) return const Expanded(child: SizedBox(height: 36));
            final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayIndex);
            final isSel = day.year == _selectedDate.year && day.month == _selectedDate.month && day.day == _selectedDate.day;
            final isToday = day.year == DateTime.now().year && day.month == DateTime.now().month && day.day == DateTime.now().day;
            final hasApt = _hasAppointments(day);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() { _selectedDate = day; _focusedMonth = DateTime(day.year, day.month); }),
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : (isToday ? AppColors.primary.withOpacity(0.15) : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayIndex', style: TextStyle(color: isSel ? Colors.black : (isToday ? AppColors.primary : AppColors.text), fontWeight: isSel || isToday ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                      if (hasApt) Container(width: 4, height: 4, decoration: BoxDecoration(color: isSel ? Colors.black : AppColors.primary, shape: BoxShape.circle)),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  String _monthName(int month) {
    const names = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return names[month - 1];
  }
}
