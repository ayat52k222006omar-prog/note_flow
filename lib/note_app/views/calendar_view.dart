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

  bool _matchesSelectedDay(NoteModel item) {
    if (item.alarmTime != null) {
      return item.alarmTime!.year == _focusedMonth.year &&
          item.alarmTime!.month == _focusedMonth.month &&
          item.alarmTime!.day == _selectedDay;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final totalDays = _daysInMonth(_focusedMonth);
    final startOffset = _firstWeekdayOffset(_focusedMonth);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(title: const Text('Calendar')),
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
                        final isSelected = day == _selectedDay;
                        final isToday = day == now.day &&
                            _focusedMonth.month == now.month &&
                            _focusedMonth.year == now.year;

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
                            child: Text(
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
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Scheduled Alarms & Events',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              if (dayItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No scheduled alarms yet.',
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
                          Icons.alarm_rounded,
                          color: isDark ? AppColors.darkAccentLavender : AppColors.primaryDark,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.primaryTextColor,
                          ),
                        ),
                        subtitle: item.alarmTime != null
                            ? Text(
                                '${item.alarmTime!.hour}:${item.alarmTime!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(color: context.secondaryTextColor),
                              )
                            : null,
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