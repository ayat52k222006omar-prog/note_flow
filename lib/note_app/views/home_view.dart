import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfirstapp/note_app/cubit/cubit/notes_cubit.dart';
import '../core/app_theme.dart';
import '../models/note_model.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/edit_task_sheet.dart';
import 'calendar_view.dart';
import 'create_note_view.dart';
import 'new_task_view.dart';
import 'notes_view.dart';
import 'profile_view.dart';
import 'tasks_view.dart';

class HomeView extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;
  final int initialIndex;

  const HomeView({
    super.key,
    this.onNavigateTab,
    this.initialIndex = 0,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final CelebrationController _celebrationController = CelebrationController();
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateToTab(int index) {
    if (index < 0 || index > 4) return;
    setState(() => _currentIndex = index);
    widget.onNavigateTab?.call(index);
  }

  void _openCreateOptions() {
    final isDark = context.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: context.elevatedCardColor,
                child: Icon(
                  Icons.note_add_outlined,
                  color: context.primaryTextColor,
                ),
              ),
              title: Text(
                'Create Note',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
              ),
              subtitle: Text(
                'Write a note with category & alarm',
                style: TextStyle(color: context.secondaryTextColor),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateNoteView()),
                );
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isDark ? AppColors.darkAccentPurple : AppColors.slateBlue,
                child: const Icon(Icons.add_task, color: Colors.white),
              ),
              title: Text(
                'New Task',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
              ),
              subtitle: Text(
                'Set priority, due date & alarm',
                style: TextStyle(color: context.secondaryTextColor),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewTaskView()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    final isDark = context.isDarkMode;

    return CelebrationOverlay(
      controller: _celebrationController,
      child: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          final cubit = BlocProvider.of<NotesCubit>(context);
          final items =
              state is NotesLoaded ? state.items : (cubit.notes ?? []);
          final notesCount = items.where((e) => !e.isTask).length;
          final tasks = items.where((e) => e.isTask).toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.primaryDark,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(28)),
                  border: isDark
                      ? const Border(
                          bottom: BorderSide(color: AppColors.darkBorder),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hello, Ayat! 👋',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Let's be productive today!",
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          backgroundColor:
                              isDark ? AppColors.darkCard : AppColors.background,
                          child: IconButton(
                            icon: Icon(
                              Icons.notifications_none,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.primaryDark,
                            ),
                            onPressed: () => _navigateToTab(3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Material(
                      color: Colors.transparent,
                      child: TextField(
                        onChanged: cubit.searchNotes,
                        style: TextStyle(color: context.primaryTextColor),
                        decoration: InputDecoration(
                          hintText: 'Search notes, tasks...',
                          hintStyle:
                              TextStyle(color: context.secondaryTextColor),
                          prefixIcon: Icon(
                            Icons.search,
                            color: context.secondaryTextColor,
                          ),
                          filled: true,
                          fillColor:
                              isDark ? AppColors.darkCard : AppColors.background,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : Colors.transparent,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkAccentPurple
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _OverviewStatCard(
                            count: '$notesCount',
                            label: 'Notes',
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.slateBlue,
                            borderColor: isDark
                                ? AppColors.darkBorder
                                : Colors.transparent,
                            badgeBg: isDark
                                ? AppColors.darkAccentPurple
                                    .withValues(alpha: 0.22)
                                : Colors.white24,
                            iconColor: isDark
                                ? AppColors.darkAccentLavender
                                : Colors.white,
                            icon: Icons.description_outlined,
                            onTap: () => _navigateToTab(1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _OverviewStatCard(
                            count: '${tasks.length}',
                            label: 'Tasks',
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.primaryDark,
                            borderColor: isDark
                                ? AppColors.darkBorder
                                : Colors.transparent,
                            badgeBg: isDark
                                ? const Color(0xFF28C76F).withValues(alpha: 0.18)
                                : Colors.white24,
                            iconColor: isDark
                                ? const Color(0xFF4CD97B)
                                : Colors.white,
                            icon: Icons.check_circle_outline,
                            onTap: () => _navigateToTab(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Overview",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _navigateToTab(2),
                          child: Text(
                            'See all →',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (tasks.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                            'No tasks yet. Tap + to add one.',
                            style: TextStyle(color: context.secondaryTextColor),
                          ),
                        ),
                      )
                    else
                      ...tasks.map(
                        (task) => _OverviewTaskRow(
                          task: task,
                          onToggleComplete: () {
                            final willComplete = !task.isCompleted;
                            cubit.toggleNoteStatus(task);
                            if (willComplete) {
                              _celebrationController.celebrate();
                            }
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    const _MotivationCard(),
                    const SizedBox(height: 76),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final pages = <Widget>[
      _buildHomeBody(context),
      const NotesView(),
      const TasksView(),
      const CalendarView(),
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: context.bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:
            isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
        shape: const CircleBorder(),
        onPressed: _openCreateOptions,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : Colors.black12,
              width: 0.8,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.cardWhite,
          selectedItemColor:
              isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
          unselectedItemColor:
              isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.note_alt_outlined),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  final String count, label;
  final Color color, borderColor, badgeBg, iconColor;
  final IconData icon;
  final VoidCallback? onTap;

  const _OverviewStatCard({
    required this.count,
    required this.label,
    required this.color,
    required this.borderColor,
    required this.badgeBg,
    required this.iconColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: badgeBg,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 14),
              Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: context.isDarkMode
                      ? AppColors.darkTextSecondary
                      : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTaskRow extends StatelessWidget {
  final NoteModel task;
  final VoidCallback onToggleComplete;

  const _OverviewTaskRow({
    required this.task,
    required this.onToggleComplete,
  });

  void _openEditor(BuildContext context) {
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.transparent,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openEditor(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Checkbox(
                  value: task.isCompleted,
                  activeColor:
                      isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  shape: const CircleBorder(),
                  onChanged: (_) => onToggleComplete(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
                      if (task.alarmTime != null)
                        Text(
                          '⏰ ${task.alarmTime!.day}/${task.alarmTime!.month}  ${task.alarmTime!.hour}:${task.alarmTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkAccentLavender
                                : AppColors.slateBlue,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkAccentPurple.withValues(alpha: 0.22)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  AppColors.darkElevatedCard,
                  AppColors.darkCard,
                ]
              : [
                  AppColors.warmSand.withValues(alpha: 0.75),
                  AppColors.softLavender.withValues(alpha: 0.65),
                ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're doing great!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep going ❤️',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '🏆',
            style: TextStyle(fontSize: 34),
          ),
        ],
      ),
    );
  }
}