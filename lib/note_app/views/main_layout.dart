import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'home_view.dart';
import 'notes_view.dart';
import 'tasks_view.dart';
import 'calendar_view.dart';
import 'profile_view.dart';
import 'create_note_view.dart';
import 'new_task_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
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
                child: Icon(Icons.note_add_outlined, color: context.primaryTextColor),
              ),
              title: Text(
                'Create Note',
                style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryTextColor),
              ),
              subtitle: Text(
                'Write a note with category & alarm',
                style: TextStyle(color: context.secondaryTextColor),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateNoteView()));
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: isDark ? AppColors.darkAccentPurple : AppColors.slateBlue,
                child: const Icon(Icons.add_task, color: Colors.white),
              ),
              title: Text(
                'New Task',
                style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryTextColor),
              ),
              subtitle: Text(
                'Set priority, due date & alarm',
                style: TextStyle(color: context.secondaryTextColor),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NewTaskView()));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final List<Widget> screens = [
      HomeView(onNavigateTab: _goToTab),
      const NotesView(),
      const TasksView(),
      const CalendarView(),
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: context.bgColor,
      body: screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
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
          onTap: _goToTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.cardWhite,
          selectedItemColor: isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
          unselectedItemColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.note_alt_outlined), label: 'Notes'),
            BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}