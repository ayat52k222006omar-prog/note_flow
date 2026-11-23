part of 'notes_cubit.dart';

abstract class NotesState {}

class NotesInitial extends NotesState {}

class NotesLoaded extends NotesState {
  final List<NoteModel> items;
  final String searchQuery;
  final String selectedCategory;
  final int taskFilter; // 0: All, 1: Active, 2: Completed

  NotesLoaded({
    required this.items,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.taskFilter = 0,
  });
}