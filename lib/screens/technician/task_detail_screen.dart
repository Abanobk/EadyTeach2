import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Map<String, dynamic> _task;
  bool _updating = false;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _task = Map.from(widget.task);
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await ApiService.mutate('tasks.updateStatus', input: {
        'taskId': _task['id'],
        'status': newStatus,
        'note': _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      });
      setState(() {
        _task['status'] = newStatus;
        _updating = false;
      });
      _noteCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الحالة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _task['status'] as String? ?? 'pending';
    final priority = _task['priority'] as String? ?? 'medium';
    final date = _task['scheduledDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(_task['scheduledDate'])
        : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('تفاصيل المهمة'),
          backgroundColor: AppColors.card,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _task['title'] ?? '',
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildPriorityBadge(priority),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatusBadge(status),
              const SizedBox(height: 16),

              // Description
              if (_task['description'] != null) ...[
                _InfoCard(
                  icon: Icons.description_outlined,
                  title: 'الوصف',
                  content: _task['description'],
                ),
                const SizedBox(height: 12),
              ],

              // Date
              if (date != null) ...[
                _InfoCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'التاريخ المحدد',
                  content:
                      '${date.day}/${date.month}/${date.year} — ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: 12),
              ],

              // Customer info
              if (_task['customerName'] != null) ...[
                _InfoCard(
                  icon: Icons.person_outline,
                  title: 'العميل',
                  content: _task['customerName'],
                ),
                const SizedBox(height: 12),
              ],

              if (_task['customerPhone'] != null) ...[
                _InfoCard(
                  icon: Icons.phone_outlined,
                  title: 'رقم الهاتف',
                  content: _task['customerPhone'],
                ),
                const SizedBox(height: 12),
              ],

              if (_task['address'] != null) ...[
                _InfoCard(
                  icon: Icons.location_on_outlined,
                  title: 'العنوان',
                  content: _task['address'],
                ),
                const SizedBox(height: 24),
              ],

              // Update Status
              const Text('تحديث الحالة',
                  style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 12),

              // Note field
              TextField(
                controller: _noteCtrl,
                style: const TextStyle(color: AppColors.text),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  hintText: 'أضف ملاحظة عند تحديث الحالة...',
                  prefixIcon: Icon(Icons.note_outlined, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 16),

              // Status buttons
              if (status == 'pending')
                _StatusButton(
                  label: 'بدء العمل',
                  icon: Icons.play_arrow_outlined,
                  color: const Color(0xFF1565C0),
                  loading: _updating,
                  onTap: () => _updateStatus('in_progress'),
                ),
              if (status == 'in_progress') ...[
                _StatusButton(
                  label: 'تم الإنجاز',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  loading: _updating,
                  onTap: () => _updateStatus('completed'),
                ),
                const SizedBox(height: 8),
                _StatusButton(
                  label: 'إلغاء المهمة',
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  loading: _updating,
                  onTap: () => _updateStatus('cancelled'),
                ),
              ],
              if (status == 'completed' || status == 'cancelled')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status == 'completed'
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: status == 'completed'
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status == 'completed'
                            ? 'تم إنجاز هذه المهمة'
                            : 'تم إلغاء هذه المهمة',
                        style: TextStyle(
                          color: status == 'completed'
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = const Color(0xFFD4920A);
        label = 'جديدة';
        break;
      case 'in_progress':
        color = const Color(0xFF1565C0);
        label = 'جاري التنفيذ';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'مكتملة';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'ملغاة';
        break;
      default:
        color = AppColors.muted;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;
    switch (priority) {
      case 'high':
        color = AppColors.error;
        label = 'عاجل';
        break;
      case 'medium':
        color = const Color(0xFFD4920A);
        label = 'متوسط';
        break;
      case 'low':
        color = AppColors.success;
        label = 'عادي';
        break;
      default:
        color = AppColors.muted;
        label = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoCard(
      {required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11)),
                const SizedBox(height: 4),
                Text(content,
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
