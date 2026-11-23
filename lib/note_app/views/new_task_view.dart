import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfirstapp/note_app/cubit/cubit/notes_cubit.dart';
import 'package:myfirstapp/note_app/models/note_model.dart';
import 'package:myfirstapp/note_app/services/alarm_service.dart';

class NewTaskView extends StatefulWidget {
  const NewTaskView({super.key});

  @override
  State<NewTaskView> createState() => _NewTaskViewState();
}

class _NewTaskViewState extends State<NewTaskView> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  String _priority = 'High';
  DateTime? _dueAlarm;
  bool _isSaving = false;

  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAlarm ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _dueAlarm != null
          ? TimeOfDay.fromDateTime(_dueAlarm!)
          : TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _dueAlarm = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveTask() async {
    if (_isSaving) return;

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() => _isSaving = true);
    debugPrint('1. NewTaskView -> saving: $title');

    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;

    final task = NoteModel(
      id: id,
      title: title,
      subTitle: _descCtrl.text.trim(),
      date: '${now.day}/${now.month}/${now.year}',
      color: const Color(0xFF2E3A4B).value,
      category: 'Task',
      priority: _priority,
      isTask: true,
      alarmTime: _dueAlarm,
    );

    try {
      debugPrint('2. Calling NotesCubit.addNote...');
      await BlocProvider.of<NotesCubit>(context).addNote(task);
      debugPrint('3. NotesCubit.addNote completed!');
    } catch (e, stack) {
      debugPrint('ERROR in NewTaskView._saveTask: $e');
      debugPrint('$stack');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
      return;
    }

    if (_dueAlarm != null && _dueAlarm!.isAfter(DateTime.now())) {
      try {
        await AlarmService.instance
            .scheduleAlarm(
              id: id,
              title: task.title,
              body: task.subTitle.isNotEmpty ? task.subTitle : 'Task alarm reminder',
              scheduledTime: _dueAlarm!,
            )
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Alarm warning in NewTaskView: $e');
      }
    }

    if (mounted) {
      debugPrint('4. Popping NewTaskView...');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0D17) : const Color(0xFFF3EFEA);
    final cardColor = isDark ? const Color(0xFF171A2E) : const Color(0xFFFAF8F5);
    final borderColor = isDark ? const Color(0xFF282E4E) : Colors.black12;
    final textPrimary = isDark ? const Color(0xFFF5F6FA) : const Color(0xFF232B35);
    final textSecondary = isDark ? const Color(0xFF9BA3C2) : const Color(0xFF6E7781);
    final accentColor = isDark ? const Color(0xFF7C6CF0) : const Color(0xFF2E3A4B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'New Task',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveTask,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  )
                : Icon(Icons.check, color: accentColor),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Task Title',
              hintStyle: TextStyle(color: textSecondary),
              filled: true,
              fillColor: cardColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add description...',
              hintStyle: TextStyle(color: textSecondary),
              filled: true,
              fillColor: cardColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Priority',
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
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
                      color: selected ? accentColor : cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? Colors.transparent : borderColor,
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
                            color: selected ? Colors.white : textPrimary,
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
          const SizedBox(height: 18),
          Text(
            'Due Date & Alarm',
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: cardColor,
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _pickDateTime,
            icon: Icon(
              Icons.alarm,
              color: _dueAlarm != null ? accentColor : textSecondary,
            ),
            label: Text(
              _dueAlarm == null
                  ? 'Select Date & Time'
                  : '${_dueAlarm!.day}/${_dueAlarm!.month}/${_dueAlarm!.year}  •  ${_dueAlarm!.hour}:${_dueAlarm!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: _dueAlarm != null ? textPrimary : textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}