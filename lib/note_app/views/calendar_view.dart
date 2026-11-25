import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfirstapp/note_app/cubit/cubit/notes_cubit.dart';
import '../core/app_theme.dart';
import '../models/note_model.dart';
import '../widgets/edit_task_sheet.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedMonth = DateTime.now();
  int _selectedDay = DateTime.now().day;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _firstWeekdayOffset(DateTime date) {
    // DateTime.weekday: Monday = 1 .. Sunday = 7 -> convert to Sunday = 0
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  DateTime? _parseDateString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // صيغة d/M/yyyy أو dd/MM/yyyy
    final slashParts = trimmed.split('/');
    if (slashParts.length == 3) {
      final d = int.tryParse(slashParts[0]);
      final m = int.tryParse(slashParts[1]);
      final y = int.tryParse(slashParts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }

    // صيغة yyyy-MM-dd أو ISO
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    return null;
  }

  DateTime? _taskDate(NoteModel item) {
    if (item.alarmTime != null) {
      return DateTime(
        item.alarmTime!.year,
        item.alarmTime!.month,
        item.alarmTime!.day,
      );
    }
    return _parseDateString(item.date);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _matchesDay(NoteModel item, DateTime targetDay) {
    if (!item.isTask) return false;
    final date = _taskDate(item);
    return date != null && _sameDay(date, targetDay);
  }

  bool _matchesSelectedDay(NoteModel item) {
    final selected =
        DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay);
    return _matchesDay(item, selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final totalDays = _daysInMonth(_focusedMonth);
    final startOffset = _firstWeekdayOffset(_focusedMonth);
    final now = DateTime.now();
    final selectedDate =
        DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay);
    final isSelectedToday = _sameDay(selectedDate, now);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => setState(() {
              _focusedMonth = DateTime.now();
              _selectedDay = DateTime.now().day;
            }),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          final cubit = BlocProvider.of<NotesCubit>(context);
          final items = state is NotesLoaded ? state.items : (cubit.notes ?? []);
          final dayItems = items.where(_matchesSelectedDay).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.black12,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left, color: context.primaryTextColor),
                              onPressed: () {
                                setState(() {
                                  _focusedMonth = DateTime(
                                    _focusedMonth.year,
                                    _focusedMonth.month - 1,
                                  );
                                  _selectedDay = 1;
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right, color: context.primaryTextColor),
                              onPressed: () {
                                setState(() {
                                  _focusedMonth = DateTime(
                                    _focusedMonth.year,
                                    _focusedMonth.month + 1,
                                  );
                                  _selectedDay = 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _weekDays
                          .map(
                            (d) => SizedBox(
                              width: 36,
                              child: Center(
                                child: Text(
                                  d,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: context.secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: startOffset + totalDays,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 4,
                      ),
                      itemBuilder: (_, index) {
                        if (index < startOffset) {
                          return const SizedBox.shrink();
                        }
                        final day = index - startOffset + 1;
                        final cellDate = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month,
                          day,
                        );
                        final isSelected = day == _selectedDay;
                        final isToday = day == now.day &&
                            _focusedMonth.month == now.month &&
                            _focusedMonth.year == now.year;
                        final hasTasks =
                            items.any((item) => _matchesDay(item, cellDate));

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = day),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? (isDark ? AppColors.darkAccentPurple : AppColors.primaryDark)
                                  : Colors.transparent,
                              border: !isSelected && isToday
                                  ? Border.all(
                                      color: isDark
                                          ? AppColors.darkAccentPurple
                                          : AppColors.primaryDark,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    fontWeight: (isSelected || isToday)
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : context.primaryTextColor,
                                  ),
                                ),
                                if (hasTasks)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkAccentLavender
                                              : AppColors.primaryDark),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSelectedToday
                        ? "Today's Tasks"
                        : 'Tasks on $_selectedDay/${_focusedMonth.month}/${_focusedMonth.year}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.primaryTextColor,
                    ),
                  ),
                  Text(
                    '${dayItems.length}',
                    style: TextStyle(fontSize: 13, color: context.secondaryTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (dayItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No tasks for this day.',
                    style: TextStyle(color: context.secondaryTextColor),
                  ),
                )
              else
                ...dayItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isDark ? AppColors.darkCard : AppColors.cardWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: context.bgColor,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => EditTaskSheet(task: item),
                        ),
                        leading: Icon(
                          item.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isDark ? AppColors.darkAccentLavender : AppColors.primaryDark,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isCompleted
                                ? context.secondaryTextColor
                                : context.primaryTextColor,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (item.alarmTime != null)
                              '${item.alarmTime!.hour}:${item.alarmTime!.minute.toString().padLeft(2, '0')}',
                            item.priority,
                            if (item.alarmTime == null) item.date,
                          ].join(' • '),
                          style: TextStyle(color: context.secondaryTextColor),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}