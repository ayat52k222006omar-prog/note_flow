import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:myfirstapp/note_app/models/note_model.dart';
import 'package:myfirstapp/note_app/services/alarm_service.dart';

part 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  NotesCubit() : super(NotesInitial());

  static const String boxName = 'notes_box';
  Box<NoteModel> get _box => Hive.box<NoteModel>(boxName);

  List<NoteModel> _allItems = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  int _taskFilter = 0;

  List<NoteModel> get notes => _allItems;

  // مفتاح Hive: String عشان الـ id كبير (millisecondsSinceEpoch)
  String _key(int id) => id.toString();

  // id صغير للمنبه (Android بيقبل 32-bit signed بس)
  int _alarmId(int id) => id.remainder(2147483647);

  void loadNotes() {
    if (!Hive.isBoxOpen(boxName)) return;

    _allItems = _box.values.toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.id.compareTo(a.id);
      });
    _emitFiltered();
  }

  Future<void> _safeScheduleAlarm(NoteModel item) async {
    if (item.alarmTime == null || item.isCompleted) return;
    if (!item.alarmTime!.isAfter(DateTime.now())) return;

    try {
      await AlarmService.instance
          .scheduleAlarm(
            id: _alarmId(item.id),
            title: item.title,
            body: item.subTitle.isNotEmpty ? item.subTitle : 'Reminder',
            scheduledTime: item.alarmTime!,
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // نتجاهل أي تأخير أو خطأ في المنبه حتى لا يعلق حفظ العنصر
    }
  }

  Future<void> _safeCancelAlarm(int id) async {
    try {
      await AlarmService.instance
          .cancelAlarm(_alarmId(id))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> addNote(NoteModel item) async {
    await _box.put(_key(item.id), item);
    loadNotes();
    await _safeScheduleAlarm(item);
  }

  Future<void> updateNote(NoteModel updated) async {
    await _box.put(_key(updated.id), updated);
    loadNotes();
    await _safeCancelAlarm(updated.id);
    await _safeScheduleAlarm(updated);
  }

  Future<void> toggleNoteStatus(NoteModel item) async {
    final nextCompleted = !item.isCompleted;
    final updated = item.copyWith(isCompleted: nextCompleted);
    await _box.put(_key(updated.id), updated);
    loadNotes();

    if (nextCompleted) {
      await _safeCancelAlarm(updated.id);
    } else {
      await _safeScheduleAlarm(updated);
    }
  }

  Future<void> deleteNote(NoteModel item) async {
    await _safeCancelAlarm(item.id);
    await _box.delete(_key(item.id));
    loadNotes();
  }

  void searchNotes(String query) {
    _searchQuery = query.trim().toLowerCase();
    _emitFiltered();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    _emitFiltered();
  }

  void setTaskFilter(int filter) {
    _taskFilter = filter;
    _emitFiltered();
  }

  void _emitFiltered() {
    final filtered = _allItems.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery) ||
          item.subTitle.toLowerCase().contains(_searchQuery);

      final matchesCategory = item.isTask ||
          _selectedCategory == 'All' ||
          item.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    emit(
      NotesLoaded(
        items: filtered,
        searchQuery: _searchQuery,
        selectedCategory: _selectedCategory,
        taskFilter: _taskFilter,
      ),
    );
  }
}