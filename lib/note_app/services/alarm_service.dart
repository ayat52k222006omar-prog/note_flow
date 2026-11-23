import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'noteflow_alarm_channel';
  static const String _channelName = 'NoteFlow Alarm';

  bool _initialized = false;

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() async {
    if (!_isSupportedPlatform || _initialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(initSettings);

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();

      _initialized = true;
    } catch (_) {
      // تجنب تعطيل تشغيل التطبيق لو فشل تهيئة المنبه
    }
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_isSupportedPlatform) return;
    if (scheduledTime.isBefore(DateTime.now())) return;

    try {
      if (!_initialized) {
        await init();
      }

      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Continuous alarm notifications for tasks and notes',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
        fullScreenIntent: true,
        ongoing: false,
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body.isEmpty ? '⏰ وقت المهمة / الملاحظة' : body,
        tzDateTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // عدم إيقاف الحفظ في حال حدوث خطأ في جدولة المنبه
    }
  }

  Future<void> cancelAlarm(int id) async {
    if (!_isSupportedPlatform) return;

    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}