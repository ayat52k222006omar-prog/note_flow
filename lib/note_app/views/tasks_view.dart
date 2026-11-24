import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfirstapp/note_app/cubit/cubit/notes_cubit.dart';
import '../core/app_theme.dart';
import '../models/note_model.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/edit_task_sheet.dart';
import '../services/alarm_service.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  int _filter = 0; // 0: All, 1: Active, 2: Completed
  int _sort = 0; // 0: Newest, 1: Priority, 2: Due time
  bool _searching = false;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final CelebrationController _celebrationController = CelebrationController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _query = '';
        _searchCtrl.clear();
      }
    });
  }

  List<NoteModel> _applyView(List<NoteModel> src) {
    var list = src;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.subTitle.toLowerCase().contains(q))
          .toList();
    }
    if (_sort == 1) {
      int rank(String p) => p == 'High' ? 0 : (p == 'Medium' ? 1 : 2);
      list = [...list]
        ..sort((a, b) => rank(a.priority).compareTo(rank(b.priority)));
    } else if (_sort == 2) {
      list = [...list]
        ..sort((a, b) {
          if (a.alarmTime == null && b.alarmTime == null) return 0;
          if (a.alarmTime == null) return 1;
          if (b.alarmTime == null) return -1;
          return a.alarmTime!.compareTo(b.alarmTime!);
        });
    }
    return list;
  }

  Future<void> _onMenu(String value) async {
    final cubit = BlocProvider.of<NotesCubit>(context);
    final state = cubit.state;
    final items = state is NotesLoaded ? state.items : (cubit.notes ?? []);
    final tasks = items.where((e) => e.isTask).toList();

    switch (value) {
      case 'sort_new':
        setState(() => _sort = 0);
        break;
      case 'sort_priority':
        setState(() => _sort = 1);
        break;
      case 'sort_time':
        setState(() => _sort = 2);
        break;
      case 'complete_all':
        final pending = tasks.where((t) => !t.isCompleted).toList();
        if (pending.isEmpty) return;
        for (final t in pending) {
          await cubit.toggleNoteStatus(t);
        }
        _celebrationController.celebrate();
        break;
      case 'clear_completed':
        final done = tasks.where((t) => t.isCompleted).toList();
        if (done.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No completed tasks to clear')),
          );
          return;
        }
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Clear completed?'),
            content: Text('Delete ${done.length} completed task(s)?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
        if (ok != true) return;
        for (final t in done) {
          await AlarmService.instance.cancelAlarm(t.id);
          await cubit.deleteNote(t);
        }
        break;
    }
  }

  String _subtitle(NoteModel t) {
    final d = t.alarmTime;
    if (d == null) return t.priority;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    final label = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Tomorrow'
            : '${d.day}/${d.month}';
    return '$label • ${t.priority}';
  }

  void _openTaskEditor(BuildContext context, NoteModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditTaskSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return CelebrationOverlay(
      controller: _celebrationController,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          title: _searching
              ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  cursorColor: context.accentColor,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(color: context.secondaryTextColor),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                )
              : const Text('Tasks'),
          actions: [
            IconButton(
              icon: Icon(_searching ? Icons.close : Icons.search),
              onPressed: _toggleSearch,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: _onMenu,
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'sort_new',
                  checked: _sort == 0,
                  child: const Text('Sort: Newest'),
                ),
                CheckedPopupMenuItem(
                  value: 'sort_priority',
                  checked: _sort == 1,
                  child: const Text('Sort: Priority'),
                ),
                CheckedPopupMenuItem(
                  value: 'sort_time',
                  checked: _sort == 2,
                  child: const Text('Sort: Due time'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'complete_all',
                  child: Text('Mark all as completed'),
                ),
                const PopupMenuItem(
                  value: 'clear_completed',
                  child: Text('Clear completed'),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<NotesCubit, NotesState>(
          builder: (context, state) {
            final cubit = BlocProvider.of<NotesCubit>(context);
            final allTasks = (state is NotesLoaded ? state.items : (cubit.notes ?? []))
                .where((e) => e.isTask)
                .toList();
            final active = allTasks.where((e) => !e.isCompleted).toList();
            final completed = allTasks.where((e) => e.isCompleted).toList();

            final visible = _applyView(
              _filter == 0 ? allTasks : (_filter == 1 ? active : completed),
            );
            final double progress =
                allTasks.isEmpty ? 0 : completed.length / allTasks.length;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _TaskFilterBtn(
                        title: 'All (${allTasks.length})',
                        selected: _filter == 0,
                        isDark: isDark,
                        onTap: () => setState(() => _filter = 0),
                      ),
                      const SizedBox(width: 8),
                      _TaskFilterBtn(
                        title: 'Active (${active.length})',
                        selected: _filter == 1,
                        isDark: isDark,
                        onTap: () => setState(() => _filter = 1),
                      ),
                      const SizedBox(width: 8),
                      _TaskFilterBtn(
                        title: 'Completed (${completed.length})',
                        selected: _filter == 2,
                        isDark: isDark,
                        onTap: () => setState(() => _filter = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: visible.isEmpty
                        ? Center(
                            child: Text(
                              _query.trim().isNotEmpty ? 'No matching tasks' : 'No tasks in this filter',
                              style: TextStyle(color: context.secondaryTextColor),
                            ),
                          )
                        : ListView.builder(
                            itemCount: visible.length,
                            itemBuilder: (_, i) {
                              final task = visible[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Dismissible(
                                  key: ValueKey(task.id),
                                  onDismissed: (_) => cubit.deleteNote(task),
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    color: context.cardColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isDark ? AppColors.darkBorder : Colors.transparent,
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: () => _openTaskEditor(context, task),
                                      leading: Checkbox(
                                        value: task.isCompleted,
                                        activeColor: isDark
                                            ? AppColors.darkAccentPurple
                                            : AppColors.primaryDark,
                                        side: BorderSide(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.textSecondary,
                                        ),
                                        shape: const CircleBorder(),
                                        onChanged: (_) {
                                          final willComplete = !task.isCompleted;
                                          cubit.toggleNoteStatus(task);
                                          if (willComplete) {
                                            _celebrationController.celebrate();
                                          }
                                        },
                                      ),
                                      title: Text(
                                        task.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          decoration: task.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: task.isCompleted
                                              ? context.secondaryTextColor
                                              : context.primaryTextColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        _subtitle(task),
                                        style: TextStyle(color: context.secondaryTextColor),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkAccentPurple.withOpacity(0.22)
                                              : AppColors.warmSand,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          task.priority,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.darkAccentLavender
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  _ProgressCard(progress: progress, isDark: isDark),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TaskFilterBtn extends StatelessWidget {
  final String title;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _TaskFilterBtn({
    required this.title,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.darkAccentPurple : AppColors.primaryDark)
              : (isDark ? AppColors.darkCard : AppColors.warmSand),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : Colors.transparent),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : context.primaryTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  final bool isDark;

  const _ProgressCard({required this.progress, required this.isDark});

  static const List<double> _bars = [0.35, 0.5, 0.42, 0.75, 1.0];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkCard : AppColors.primaryDark;
    final accent = isDark ? AppColors.darkAccentLavender : AppColors.softLavender;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: accent,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: Colors.white24,
                        color: accent,
                      ),
                    ),
                    // مساحة فاضية عشان زرار + ما يغطيش الشريط
                    const SizedBox(width: 56),
                  ],
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_bars.length, (i) {
              final reached = (i + 1) / _bars.length <= progress + 0.0001;
              return Container(
                width: 6,
                height: 8 + 26 * _bars[i],
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: reached ? accent : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}