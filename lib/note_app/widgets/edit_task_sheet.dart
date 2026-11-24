import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfirstapp/note_app/cubit/cubit/notes_cubit.dart';
import '../core/app_theme.dart';
import '../models/note_model.dart';
import '../services/alarm_service.dart';
import 'rich_text_tools.dart';

class EditTaskSheet extends StatefulWidget {
  final NoteModel task;

  const EditTaskSheet({super.key, required this.task});

  @override
  State<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<EditTaskSheet> {
  late final TextEditingController _titleController;
  late final RichTextController _descController;
  late final List<String> _tags;
  late String _priority;
  DateTime? _alarmTime;

  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    final parts = splitTags(widget.task.subTitle);
    _descController = RichTextController(text: parts.$1);
    _tags = parts.$2;
    _priority = _priorities.contains(widget.task.priority)
        ? widget.task.priority
        : 'Medium';
    _alarmTime = widget.task.alarmTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAlarm() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _alarmTime ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _alarmTime != null
          ? TimeOfDay.fromDateTime(_alarmTime!)
          : TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _alarmTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final cubit = BlocProvider.of<NotesCubit>(context);
    final updated = widget.task.copyWith(
      title: title,
      subTitle: joinTags(_descController.text.trim(), _tags),
      priority: _priority,
      alarmTime: _alarmTime,
    );

    await cubit.updateNote(updated);

    if (_alarmTime != null && _alarmTime!.isAfter(DateTime.now())) {
      await AlarmService.instance.scheduleAlarm(
        id: updated.id,
        title: updated.title,
        body: stripRich(updated.subTitle).isNotEmpty
            ? stripRich(updated.subTitle)
            : 'Scheduled reminder',
        scheduledTime: _alarmTime!,
      );
    } else {
      await AlarmService.instance.cancelAlarm(updated.id);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteItem() async {
    final cubit = BlocProvider.of<NotesCubit>(context);
    await AlarmService.instance.cancelAlarm(widget.task.id);
    await cubit.deleteNote(widget.task);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.warmSand,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.task.isTask ? 'Edit Task' : 'Edit Note',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: context.primaryTextColor,
                  ),
                ),
                IconButton(
                  onPressed: _deleteItem,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              style: TextStyle(color: context.primaryTextColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: context.secondaryTextColor),
                filled: true,
                fillColor: context.cardColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : Colors.black12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!widget.task.isTask) ...[
              RichToolbar(
                controller: _descController,
                cardColor: context.cardColor,
                borderColor: isDark ? AppColors.darkBorder : Colors.black12,
                iconColor: context.secondaryTextColor,
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _descController,
              maxLines: 4,
              style: TextStyle(color: context.primaryTextColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Description / Details...',
                hintStyle: TextStyle(color: context.secondaryTextColor),
                filled: true,
                fillColor: context.cardColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : Colors.black12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            if (widget.task.isTask) ...[
              const SizedBox(height: 16),
              Text(
                'Priority',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final selected = _priority == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? (isDark ? AppColors.darkAccentPurple : AppColors.primaryDark)
                              : context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : (isDark ? AppColors.darkBorder : Colors.black26),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected) ...[
                              const Icon(Icons.check, size: 15, color: Colors.white),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              p,
                              style: TextStyle(
                                color: selected ? Colors.white : context.primaryTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: context.cardColor,
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.black26,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _pickAlarm,
              icon: Icon(
                Icons.alarm,
                color: _alarmTime != null
                    ? (isDark ? AppColors.darkAccentLavender : AppColors.primaryDark)
                    : context.secondaryTextColor,
              ),
              label: Text(
                _alarmTime == null
                    ? 'Set Alarm'
                    : 'Alarm: ${_alarmTime!.day}/${_alarmTime!.month}  ${_alarmTime!.hour}:${_alarmTime!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: _alarmTime != null
                      ? context.primaryTextColor
                      : context.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saveChanges,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}