import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfirstapp/note_app/cubit/cubit/notes_cubit.dart';
import '../core/app_theme.dart';
import '../models/note_model.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/edit_task_sheet.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  int _filter = 0; // 0: All, 1: Active, 2: Completed
  final CelebrationController _celebrationController = CelebrationController();

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
        appBar: AppBar(title: const Text('Tasks')),
        body: BlocBuilder<NotesCubit, NotesState>(
          builder: (context, state) {
            final cubit = BlocProvider.of<NotesCubit>(context);
            final allTasks = (state is NotesLoaded ? state.items : (cubit.notes ?? []))
                .where((e) => e.isTask)
                .toList();
            final active = allTasks.where((e) => !e.isCompleted).toList();
            final completed = allTasks.where((e) => e.isCompleted).toList();

            final visible = _filter == 0
                ? allTasks
                : (_filter == 1 ? active : completed);
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
                              'No tasks in this filter',
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
                                        'Priority: ${task.priority}${task.alarmTime != null ? ' • ⏰ ${task.alarmTime!.hour}:${task.alarmTime!.minute.toString().padLeft(2, '0')}' : ''}',
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.warmSand,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Progress',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.primaryTextColor,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkAccentLavender
                                    : context.primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: isDark ? Colors.white12 : Colors.white60,
                          color: isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
                        ),
                      ],
                    ),
                  ),
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