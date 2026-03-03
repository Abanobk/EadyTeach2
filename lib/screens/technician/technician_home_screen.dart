import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'task_detail_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  List<dynamic> _tasks = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.query('tasks.getMyTasks');
      setState(() {
        _tasks = res['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredTasks {
    if (_filter == 'all') return _tasks;
    return _tasks.where((t) => t['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('مهامي',
                  style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text(auth.user?.name ?? '',
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.muted),
              onPressed: _loadTasks,
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
        body: Column(
          children: [
            // Filter chips
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _FilterChip(
                      label: 'الكل',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all')),
                  _FilterChip(
                      label: 'جديدة',
                      selected: _filter == 'pending',
                      onTap: () => setState(() => _filter = 'pending')),
                  _FilterChip(
                      label: 'جاري',
                      selected: _filter == 'in_progress',
                      onTap: () => setState(() => _filter = 'in_progress')),
                  _FilterChip(
                      label: 'مكتملة',
                      selected: _filter == 'completed',
                      onTap: () => setState(() => _filter = 'completed')),
                ],
              ),
            ),
            // Tasks
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : _filteredTasks.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task_outlined,
                                  size: 64, color: AppColors.muted),
                              SizedBox(height: 16),
                              Text('لا توجد مهام',
                                  style: TextStyle(
                                      color: AppColors.muted, fontSize: 18)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (ctx, i) => _TaskCard(
                            task: _filteredTasks[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(
                                    task: _filteredTasks[i]),
                              ),
                            ).then((_) => _loadTasks()),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.text,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = task['status'] as String? ?? 'pending';
    final priority = task['priority'] as String? ?? 'medium';
    final date = task['scheduledDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(task['scheduledDate'])
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task['title'] ?? '',
                    style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
                _PriorityBadge(priority: priority),
              ],
            ),
            if (task['description'] != null) ...[
              const SizedBox(height: 6),
              Text(
                task['description'],
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusBadge(status: status),
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = const Color(0xFFD4920A);
        label = 'جديدة';
        break;
      case 'in_progress':
        color = const Color(0xFF1565C0);
        label = 'جاري';
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
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
