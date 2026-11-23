import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfirstapp/note_app/core/app_theme.dart';
import 'package:myfirstapp/note_app/cubit/cubit/notes_cubit.dart';
import 'package:myfirstapp/note_app/models/note_model.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'Medium';
  bool _isTask = true;
  DateTime? _selectedAlarm;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedAlarm ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedAlarm != null
          ? TimeOfDay.fromDateTime(_selectedAlarm!)
          : TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedAlarm = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final note = NoteModel(
      id: now.millisecondsSinceEpoch,
      title: title,
      subTitle: _descController.text.trim(),
      date: '${now.day}/${now.month}/${now.year}',
      color: AppColors.warmSand.value,
      category: _isTask ? 'Task' : 'Work',
      isTask: _isTask,
      priority: _priority,
      alarmTime: _selectedAlarm,
    );

    try {
      await context
          .read<NotesCubit>()
          .addNote(note)
          .timeout(const Duration(seconds: 4));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('AddTaskSheet save error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isTask ? 'New Task' : 'Create Note',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Task')),
                  ButtonSegment(value: false, label: Text('Note')),
                ],
                selected: {_isTask},
                onSelectionChanged: (val) => setState(() => _isTask = val.first),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            style: TextStyle(color: context.primaryTextColor),
            decoration: InputDecoration(
              hintText: 'Title...',
              hintStyle: TextStyle(color: context.secondaryTextColor),
              filled: true,
              fillColor: context.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descController,
            maxLines: 2,
            style: TextStyle(color: context.primaryTextColor),
            decoration: InputDecoration(
              hintText: 'Add description...',
              hintStyle: TextStyle(color: context.secondaryTextColor),
              filled: true,
              fillColor: context.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Priority',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['High', 'Medium', 'Low'].map((p) {
              final selected = _priority == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(p),
                  selected: selected,
                  selectedColor:
                      isDark ? AppColors.darkAccentPurple : AppColors.slateBlue,
                  backgroundColor: context.cardColor,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : context.primaryTextColor,
                  ),
                  onSelected: (_) => setState(() => _priority = p),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickDateTime,
            icon: Icon(
              Icons.alarm,
              color: isDark ? AppColors.darkAccentLavender : AppColors.primaryDark,
            ),
            label: Text(
              _selectedAlarm == null
                  ? 'Set Alarm (Date & Time)'
                  : '${_selectedAlarm!.day}/${_selectedAlarm!.month} - ${_selectedAlarm!.hour}:${_selectedAlarm!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: context.primaryTextColor),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isSaving ? null : _handleSave,
              child: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}