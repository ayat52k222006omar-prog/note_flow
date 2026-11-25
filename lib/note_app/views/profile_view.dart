import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfirstapp/note_app/cubit/cubit/notes_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/theme_controller.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const String _defaultSoundPrefKey = 'default_alarm_sound_file';

  String _userName = 'Ahmed Talaat';
  String _userEmail = 'ahmedtalet477@gmail.com';
  String _lastSyncText = 'Synced 2m ago';

  bool _alarmSoundEnabled = true;
  bool _overdueAlertsEnabled = true;
  bool _appLockEnabled = false;
  bool _confirmBeforeDelete = true;

  final AudioPlayer _previewPlayer = AudioPlayer();
  String _selectedSoundFile = 'sound1.mp3';
  String? _playingSoundFile;
  void Function(void Function())? _activeModalUpdater;

  static const _soundOptions = [
    {'file': 'sound1.mp3', 'label': 'Sound 1'},
    {'file': 'sound2.mp3', 'label': 'Sound 2'},
    {'file': 'sound3.mp3', 'label': 'Sound 3'},
    {'file': 'sound4.mp3', 'label': 'Sound 4'},
    {'file': 'sound5.mp3', 'label': 'Sound 5'},
    {'file': 'sound6.mp3', 'label': 'Sound 6'},
    {'file': 'sound7.mp3', 'label': 'Sound 7'},
    {'file': 'sound8.mp3', 'label': 'Sound 8'},
  ];

  bool get _isDark => AppThemeController.instance.isDark;

  Color get _surfaceCardColor =>
      _isDark ? AppColors.darkCard : AppColors.cardWhite.withOpacity(0.85);

  Color get _primaryTextColor =>
      _isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get _secondaryTextColor =>
      _isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

  @override
  void initState() {
    super.initState();
    _loadSavedSound();
    _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        _activeModalUpdater?.call(() => _playingSoundFile = null);
        setState(() => _playingSoundFile = null);
      }
    });
  }

  Future<void> _loadSavedSound() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_defaultSoundPrefKey);
    if (saved != null &&
        _soundOptions.any((opt) => opt['file'] == saved) &&
        mounted) {
      setState(() => _selectedSoundFile = saved);
    }
  }

  Future<void> _saveDefaultSound(
    String fileName,
    void Function(void Function()) setModalState,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultSoundPrefKey, fileName);
    if (mounted) {
      setModalState(() => _selectedSoundFile = fileName);
      setState(() => _selectedSoundFile = fileName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Default alarm sound set to $fileName')),
      );
    }
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePreviewSound(
    String fileName,
    void Function(void Function()) setModalState,
  ) async {
    if (!_alarmSoundEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable Alarm Sound first to listen')),
      );
      return;
    }

    if (_playingSoundFile == fileName) {
      await _previewPlayer.stop();
      if (mounted) {
        setModalState(() => _playingSoundFile = null);
        setState(() => _playingSoundFile = null);
      }
      return;
    }

    try {
      await _previewPlayer.stop();
      await _previewPlayer.play(AssetSource('sounds/$fileName'));
      if (mounted) {
        setModalState(() => _playingSoundFile = fileName);
        setState(() => _playingSoundFile = fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play $fileName: $e')),
        );
      }
    }
  }

  Future<void> _stopPreview(void Function(void Function())? setModalState) async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
    if (mounted) {
      setModalState?.call(() => _playingSoundFile = null);
      setState(() => _playingSoundFile = null);
    }
  }

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDark ? AppColors.darkSurface : AppColors.cardWhite,
        title: Text('Edit Profile', style: TextStyle(color: _primaryTextColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: _primaryTextColor),
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              style: TextStyle(color: _primaryTextColor),
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _userName = nameCtrl.text.trim();
                  _userEmail = emailCtrl.text.trim();
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSheet({required String title, required Widget child}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDark ? AppColors.darkSurface : AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white24 : AppColors.warmSand,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _primaryTextColor,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  void _openMyStats() {
    final cubit = BlocProvider.of<NotesCubit>(context);
    final items = cubit.notes ?? [];
    final notesCount = items.where((e) => !e.isTask).length;
    final tasks = items.where((e) => e.isTask).toList();
    final completedCount = tasks.where((e) => e.isCompleted).length;
    final alarmsCount = items.where((e) => e.alarmTime != null).length;
    final double ratio = tasks.isEmpty ? 0 : completedCount / tasks.length;

    _showSheet(
      title: 'My Stats',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatMiniBox(
                  label: 'Notes',
                  value: '$notesCount',
                  color: AppColors.slateBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatMiniBox(
                  label: 'Tasks',
                  value: '${tasks.length}',
                  color: AppColors.darkAccentPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatMiniBox(
                  label: 'Alarms',
                  value: '$alarmsCount',
                  color: const Color(0xFF4F6D7A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceCardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completed Tasks',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _primaryTextColor,
                      ),
                    ),
                    Text(
                      '$completedCount / ${tasks.length} (${(ratio * 100).toInt()}%)',
                      style: TextStyle(color: _secondaryTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: _isDark ? Colors.white12 : AppColors.warmSand,
                  color: _isDark ? AppColors.darkAccentPurple : AppColors.primaryDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openNotifications() {
    void Function(void Function())? modalUpdater;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? AppColors.darkSurface : AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          modalUpdater = setModalState;
          _activeModalUpdater = setModalState;
          final accent = _isDark ? AppColors.darkAccentPurple : AppColors.primaryDark;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: _isDark ? Colors.white24 : AppColors.warmSand,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Notifications & Alarms',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Alarm Sound', style: TextStyle(color: _primaryTextColor)),
                    subtitle: Text(
                      'Play sound when scheduled alarms trigger',
                      style: TextStyle(color: _secondaryTextColor),
                    ),
                    value: _alarmSoundEnabled,
                    activeColor: AppColors.darkAccentPurple,
                    onChanged: (v) async {
                      if (!v) await _stopPreview(setModalState);
                      setModalState(() => _alarmSoundEnabled = v);
                      setState(() => _alarmSoundEnabled = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Due & Reminder Alerts',
                      style: TextStyle(color: _primaryTextColor),
                    ),
                    subtitle: Text(
                      'Notify for upcoming tasks and notes',
                      style: TextStyle(color: _secondaryTextColor),
                    ),
                    value: _overdueAlertsEnabled,
                    activeColor: AppColors.darkAccentPurple,
                    onChanged: (v) {
                      setModalState(() => _overdueAlertsEnabled = v);
                      setState(() => _overdueAlertsEnabled = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Listen & Choose Default Sound',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 290),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _soundOptions.length,
                      itemBuilder: (_, index) {
                        final opt = _soundOptions[index];
                        final file = opt['file']!;
                        final label = opt['label']!;
                        final isSelected = _selectedSoundFile == file;
                        final isPlaying = _playingSoundFile == file;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _surfaceCardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? accent
                                  : (_isDark ? AppColors.darkBorder : Colors.transparent),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            onTap: () => _saveDefaultSound(file, setModalState),
                            leading: IconButton(
                              tooltip: isPlaying ? 'Stop sound' : 'Listen first',
                              icon: Icon(
                                isPlaying
                                    ? Icons.stop_circle_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: _alarmSoundEnabled ? accent : _secondaryTextColor,
                                size: 28,
                              ),
                              onPressed: () => _togglePreviewSound(file, setModalState),
                            ),
                            title: Text(
                              label,
                              style: TextStyle(
                                color: _primaryTextColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              isPlaying
                                  ? 'Playing preview...'
                                  : (isSelected ? 'Default • $file' : file),
                              style: TextStyle(
                                color: (isPlaying || isSelected)
                                    ? accent
                                    : _secondaryTextColor,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              color: isSelected ? accent : _secondaryTextColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      _activeModalUpdater = null;
      _stopPreview(modalUpdater);
    });
  }

  void _openSecurity() {
    _showSheet(
      title: 'Security',
      child: StatefulBuilder(
        builder: (ctx, setModalState) => Column(
          children: [
            SwitchListTile(
              title: Text('App Lock', style: TextStyle(color: _primaryTextColor)),
              subtitle: Text(
                'Require lock when opening NoteFlow',
                style: TextStyle(color: _secondaryTextColor),
              ),
              value: _appLockEnabled,
              activeColor: AppColors.darkAccentPurple,
              onChanged: (v) {
                setModalState(() => _appLockEnabled = v);
                setState(() => _appLockEnabled = v);
              },
            ),
            SwitchListTile(
              title: Text(
                'Confirm Before Delete',
                style: TextStyle(color: _primaryTextColor),
              ),
              subtitle: Text(
                'Ask confirmation before removing items',
                style: TextStyle(color: _secondaryTextColor),
              ),
              value: _confirmBeforeDelete,
              activeColor: AppColors.darkAccentPurple,
              onChanged: (v) {
                setModalState(() => _confirmBeforeDelete = v);
                setState(() => _confirmBeforeDelete = v);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openHelpSupport() {
    _showSheet(
      title: 'Help & Support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HelpItem(
            text: 'Tap any task to edit its title, description, priority, or alarm.',
            textColor: _primaryTextColor,
            dotColor: _primaryTextColor,
          ),
          _HelpItem(
            text: 'Check a task box in Home or Tasks to celebrate completion.',
            textColor: _primaryTextColor,
            dotColor: _primaryTextColor,
          ),
          _HelpItem(
            text: 'Swipe a task horizontally to delete it from local Hive storage.',
            textColor: _primaryTextColor,
            dotColor: _primaryTextColor,
          ),
          const SizedBox(height: 6),
          Text(
            'Support: 01505309975 • support@noteflow.app',
            style: TextStyle(
              fontSize: 13,
              color: _secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openAboutApp() {
    _showSheet(
      title: 'About NoteFlow',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceCardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NoteFlow',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: _secondaryTextColor, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              'Personal notes and tasks manager with local Hive storage and scheduled alarm notifications.',
              style: TextStyle(fontSize: 14, color: _primaryTextColor),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerSync() {
    BlocProvider.of<NotesCubit>(context).loadNotes();
    setState(() => _lastSyncText = 'Synced just now');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hive local data synced')),
    );
  }

  Future<void> _toggleAppearance() async {
    await AppThemeController.instance.toggleDarkMode();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF28224A),
                      const Color(0xFF1A1733),
                      AppColors.darkSurface,
                    ]
                  : [
                      AppColors.slateBlue,
                      const Color(0xFF4D5E72),
                      AppColors.primaryDark,
                    ],
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkAccentPurple : AppColors.warmSand,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.cardWhite,
                      child: Icon(
                        Icons.face_3_rounded,
                        size: 48,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: _editProfileDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkAccentLavender : AppColors.warmSand,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryDark, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _userEmail,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ProfileMenuRow(
          cardColor: _surfaceCardColor,
          borderColor: isDark ? AppColors.darkBorder : Colors.transparent,
          titleColor: _primaryTextColor,
          subtitleColor: _secondaryTextColor,
          iconColor: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
          leadingBg: AppColors.softLavender.withOpacity(isDark ? 0.25 : 0.55),
          leadingIcon: Icons.bar_chart_rounded,
          title: 'My Stats',
          trailing: Icon(Icons.chevron_right, color: _secondaryTextColor),
          onTap: _openMyStats,
        ),
        _ProfileMenuRow(
          cardColor: _surfaceCardColor,
          borderColor: isDark ? AppColors.darkBorder : Colors.transparent,
          titleColor: _primaryTextColor,
          subtitleColor: _secondaryTextColor,
          iconColor: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
          leadingBg: isDark ? const Color(0xFF28384A) : const Color(0xFFD6E2F0),
          leadingIcon: Icons.cloud_done_rounded,
          title: 'Sync & Backup',
          subtitle: _lastSyncText,
          trailing: const Icon(Icons.check_circle, color: Color(0xFF2E8B57), size: 22),
          onTap: _triggerSync,
        ),
        _ProfileMenuRow(
          cardColor: _surfaceCardColor,
          borderColor: isDark ? AppColors.darkBorder : Colors.transparent,
          titleColor: _primaryTextColor,
          subtitleColor: _secondaryTextColor,
          iconColor: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
          leadingBg: isDark ? const Color(0xFF2E3C4E) : const Color(0xFFF6E7C8),
          leadingIcon: isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
          title: 'Appearance',
          subtitle: isDark ? 'Dark Mode' : 'Light Mode',
          trailing: Icon(
            isDark ? Icons.nights_stay_rounded : Icons.wb_sunny,
            color: isDark ? const Color(0xFF9BB4D4) : const Color(0xFFE09F3E),
            size: 22,
          ),
          onTap: _toggleAppearance,
        ),
        _ProfileMenuRow(
          cardColor: _surfaceCardColor,
          borderColor: isDark ? AppColors.darkBorder : Colors.transparent,
          titleColor: _primaryTextColor,
          subtitleColor: _secondaryTextColor,
          iconColor: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
          leadingBg: isDark ? const Color(0xFF3A2D32) : const Color(0xFFF3D8D2),
          leadingIcon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Sound: $_selectedSoundFile',
          trailing: Icon(Icons.chevron_right, color: _secondaryTextColor),
          onTap: _openNotifications,
        ),
        _ProfileMenuRow(
          cardColor: _surfaceCardColor,
          borderColor: isDark ? AppColors.darkBorder : Colors.transparent,
          titleColor: _primaryTextColor,
          subtitleColor: _secondaryTextColor,
          iconColor: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
          leadingBg: isDark ? const Color(0xFF2B3540) : const Color(0xFFE2E6EC),
          leadingIcon: Icons.verified_user_outlined,
          title: 'Security',
          trailing: Icon(Icons.chevron_right, color: _secondaryTextColor),
          onTap: _openSecurity,
        ),
        _ProfileMenuRow(
          cardColor: _surfaceCardColor,
          borderColor: isDark ? AppColors.darkBorder : Colors.transparent,
          titleColor: _primaryTextColor,
          subtitleColor: _secondaryTextColor,
          iconColor: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
          leadingBg: isDark ? const Color(0xFF2D333B) : const Color(0xFFE3E4EA),
          leadingIcon: Icons.help_outline_rounded,
          title: 'Help & Support',
          trailing: Icon(Icons.chevron_right, color: _secondaryTextColor),
          onTap: _openHelpSupport,
        ),
        _ProfileMenuRow(
          cardColor: _surfaceCardColor,
          borderColor: isDark ? AppColors.darkBorder : Colors.transparent,
          titleColor: _primaryTextColor,
          subtitleColor: _secondaryTextColor,
          iconColor: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
          leadingBg: isDark ? const Color(0xFF322F3E) : const Color(0xFFE4E1EC),
          leadingIcon: Icons.info_outline_rounded,
          title: 'About App',
          trailing: Icon(Icons.chevron_right, color: _secondaryTextColor),
          onTap: _openAboutApp,
        ),
      ],
    );
  }
}

class _StatMiniBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatMiniBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color dotColor;

  const _HelpItem({
    required this.text,
    required this.textColor,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: CircleAvatar(radius: 3.5, backgroundColor: dotColor),
          ),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: textColor))),
        ],
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color iconColor;
  final Color leadingBg;
  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _ProfileMenuRow({
    required this.cardColor,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.iconColor,
    required this.leadingBg,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          radius: 19,
          backgroundColor: leadingBg,
          child: Icon(leadingIcon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: titleColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}