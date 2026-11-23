import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String subTitle;

  @HiveField(3)
  final String date;

  @HiveField(4)
  int color;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  DateTime? alarmTime;

  @HiveField(7)
  String category; // All, Work, Personal, Study

  @HiveField(8)
  String priority; // High, Medium, Low

  @HiveField(9)
  bool isTask;

  @HiveField(10)
  bool isPinned;

  NoteModel({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.date,
    required this.color,
    this.isCompleted = false,
    this.alarmTime,
    this.category = 'Work',
    this.priority = 'Medium',
    this.isTask = false,
    this.isPinned = false,
  });

  NoteModel copyWith({
    int? id,
    String? title,
    String? subTitle,
    String? date,
    int? color,
    bool? isCompleted,
    DateTime? alarmTime,
    bool clearAlarm = false,
    String? category,
    String? priority,
    bool? isTask,
    bool? isPinned,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      date: date ?? this.date,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      alarmTime: clearAlarm ? null : (alarmTime ?? this.alarmTime),
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isTask: isTask ?? this.isTask,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}