import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmSoundOption {
  final String id;
  final String label;
  final String assetPath;

  const AlarmSoundOption({
    required this.id,
    required this.label,
    required this.assetPath,
  });
}

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  static const String _defaultSoundPrefKey = 'noteflow_default_alarm_sound_id';

  static const List<AlarmSoundOption> soundOptions = [
    AlarmSoundOption(
      id: 'sound1',
      label: 'صوت 1',
      assetPath: 'assets/sounds/sound1.mp3',
    ),
    AlarmSoundOption(
      id: 'sound2',
      label: 'صوت 2',
      assetPath: 'assets/sounds/sound2.mp3',
    ),
    AlarmSoundOption(
      id: 'sound3',
      label: 'صوت 3',
      assetPath: 'assets/sounds/sound3.mp3',
    ),
    AlarmSoundOption(
      id: 'sound4',
      label: 'صوت 4',
      assetPath: 'assets/sounds/sound4.mp3',
    ),
    AlarmSoundOption(
      id: 'sound5',
      label: 'صوت 5',
      assetPath: 'assets/sounds/sound5.mp3',
    ),
    AlarmSoundOption(
      id: 'sound6',
      label: 'صوت 6',
      assetPath: 'assets/sounds/sound6.mp3',
    ),
    AlarmSoundOption(
      id: 'sound7',
      label: 'صوت 7',
      assetPath: 'assets/sounds/sound7.mp3',
    ),
    AlarmSoundOption(
      id: 'sound8',
      label: 'صوت 8',
      assetPath: 'assets/sounds/sound8.mp3',
    ),
  ];

  String _defaultSoundId = soundOptions.first.id;

  String get defaultSoundId => _defaultSoundId;

  AlarmSoundOption optionById(String? id) {
    if (id == null || id.trim().isEmpty) {
      return soundOptions.firstWhere(
        (e) => e.id == _defaultSoundId,
        orElse: () => soundOptions.first,
      );
    }
    return soundOptions.firstWhere(
      (e) => e.id == id || e.assetPath == id,
      orElse: () => soundOptions.firstWhere(
        (e) => e.id == _defaultSoundId,
        orElse: () => soundOptions.first,
      ),
    );
  }

  String resolveAudioPath(String? soundKeyOrPath) {
    return optionById(soundKeyOrPath).assetPath;
  }

  Future<void> setDefaultSound(String soundId) async {
    final validId = optionById(soundId).id;
    _defaultSoundId = validId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultSoundPrefKey, validId);
      debugPrint('AlarmService: default sound updated to $validId');
    } catch (e) {
      debugPrint('AlarmService.setDefaultSound error: $e');
    }
  }

  Future<void> _loadSavedDefaultSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_defaultSoundPrefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _defaultSoundId = optionById(saved).id;
      }
    } catch (e) {
      debugPrint('AlarmService._loadSavedDefaultSound error: $e');
    }
  }

  bool _initialized = false;

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  int _normalizeId(int id) {
    final positive = id.abs();
    return positive == 0 ? 1 : positive;
  }

  Future<void> init() async {
    await _loadSavedDefaultSound();
    if (!_isSupportedPlatform || _initialized) return;

    try {
      await Alarm.init();
      _initialized = true;
      debugPrint(
        'AlarmService initialized (defaultSound=$_defaultSoundId).',
      );
    } catch (e, st) {
      debugPrint('AlarmService.init error: $e\n$st');
    }
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundOption,
  }) async {
    if (!_isSupportedPlatform) {
      debugPrint('AlarmService: skipped (not Android)');
      return;
    }

    if (!scheduledTime.isAfter(DateTime.now())) {
      debugPrint('AlarmService: scheduledTime is in the past, skipping');
      return;
    }

    try {
      if (!_initialized) {
        await init();
      }

      final alarmId = _normalizeId(id);
      final audioPath = resolveAudioPath(soundOption);
      final message = body.trim().isEmpty ? '⏰ وقت التنبيه' : body.trim();

      final alarmSettings = AlarmSettings(
        id: alarmId,
        dateTime: scheduledTime,
        assetAudioPath: audioPath,
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: true,
        volumeSettings: VolumeSettings.fixed(
          volume: 0.9,
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: title.trim().isEmpty ? 'NoteFlow' : title.trim(),
          body: message,
          stopButton: 'إيقاف',
          icon: 'mipmap/ic_launcher',
        ),
      );

      final scheduled = await Alarm.set(alarmSettings: alarmSettings);
      debugPrint(
        'AlarmService: scheduled #$alarmId at $scheduledTime ($audioPath) -> $scheduled',
      );
    } catch (e, st) {
      debugPrint('AlarmService.scheduleAlarm error: $e\n$st');
    }
  }

  Future<void> testNow({String? soundOption}) async {
    if (!_isSupportedPlatform) return;

    await scheduleAlarm(
      id: 999999,
      title: 'Test alarm',
      body: 'اختبار صوت المنبه ✅',
      scheduledTime: DateTime.now().add(const Duration(seconds: 2)),
      soundOption: soundOption,
    );
  }

  Future<void> cancelAlarm(int id) async {
    if (!_isSupportedPlatform) return;

    try {
      final alarmId = _normalizeId(id);
      await Alarm.stop(alarmId);
      debugPrint('AlarmService: cancelled #$alarmId');
    } catch (e) {
      debugPrint('AlarmService.cancelAlarm error: $e');
    }
  }
}