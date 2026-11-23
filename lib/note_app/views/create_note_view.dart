import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfirstapp/note_app/cubit/cubit/notes_cubit.dart';
import 'package:myfirstapp/note_app/models/note_model.dart';
import 'package:myfirstapp/note_app/services/alarm_service.dart';

class CreateNoteView extends StatefulWidget {
  const CreateNoteView({super.key});

  @override
  State<CreateNoteView> createState() => _CreateNoteViewState();
}

class _CreateNoteViewState extends State<CreateNoteView> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();

  String _selectedCategory = 'Work';
  int _selectedColorIndex = 0;
  bool _isPinned = false;
  DateTime? _alarmTime;
  bool _isSaving = false;

  final List<String> _categories = ['Work', 'Personal', 'Study'];
  final List<Color> _cardColors = [
    const Color(0xFFDCD3C6),
    const Color(0xFF738598),
    const Color(0xFFC9C4D8),
    const Color(0xFFD5E2D8),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
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

  Future<void> _saveNote() async {
    if (_isSaving) return;

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note title')),
      );
      return;
    }

    setState(() => _isSaving = true);
    debugPrint('1. CreateNoteView -> saving: $title');

    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;

    final note = NoteModel(
      id: id,
      title: title,
      subTitle: _bodyCtrl.text.trim(),
      date: '${now.day}/${now.month}/${now.year}',
      color: _cardColors[_selectedColorIndex].value,
      category: _selectedCategory,
      isTask: false,
      isPinned: _isPinned,
      alarmTime: _alarmTime,
    );

    try {
      debugPrint('2. Calling NotesCubit.addNote...');
      await BlocProvider.of<NotesCubit>(context).addNote(note);
      debugPrint('3. NotesCubit.addNote completed!');
    } catch (e, stack) {
      debugPrint('ERROR in CreateNoteView._saveNote: $e');
      debugPrint('$stack');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
      return;
    }

    if (_alarmTime != null && _alarmTime!.isAfter(DateTime.now())) {
      try {
        await AlarmService.instance
            .scheduleAlarm(
              id: id,
              title: note.title,
              body: note.subTitle.isNotEmpty ? note.subTitle : 'Note reminder',
              scheduledTime: _alarmTime!,
            )
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Alarm warning in CreateNoteView: $e');
      }
    }

    if (mounted) {
      debugPrint('4. Popping CreateNoteView...');
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
          'Create Note',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveNote,
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
              hintText: 'Note Title',
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
            controller: _bodyCtrl,
            maxLines: 6,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Write your note...',
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
            'Category',
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: _categories.map((cat) {
              final selected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          cat,
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
            'Card Color',
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_cardColors.length, (index) {
              final isSelected = _selectedColorIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _cardColors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF2E3A4B))
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Pin Note', style: TextStyle(color: textPrimary)),
            value: _isPinned,
            activeColor: accentColor,
            onChanged: (v) => setState(() => _isPinned = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.alarm, color: textSecondary),
            title: Text(
              _alarmTime == null
                  ? 'Set Alarm'
                  : 'Alarm: ${_alarmTime!.day}/${_alarmTime!.month}  ${_alarmTime!.hour}:${_alarmTime!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: textPrimary),
            ),
            onTap: _pickAlarm,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSaving ? null : _saveNote,
              child: Text(
                _isSaving ? 'Saving...' : 'Save Note',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}