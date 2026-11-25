import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import 'main_layout.dart';

class OnboardingView extends StatefulWidget {
  final Widget? nextPage;

  const OnboardingView({super.key, this.nextPage});

  static const String _prefKey = 'noteflow_onboarding_completed';

  static Future<bool> hasCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}
  }

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageCtrl = PageController();
  int _page = 0;
  bool _isNavigating = false;

  static const _pages = [
    (
      Icons.self_improvement_rounded,
      'Your Productivity\nCompanion',
      'Take notes, manage tasks,\nand stay organized effectively.'
    ),
    (
      Icons.alarm_on_rounded,
      'Never Miss a Thing',
      'Set alarms and reminders for\nyour tasks and notes.'
    ),
    (
      Icons.emoji_events_rounded,
      'Celebrate Progress',
      'Track your progress and enjoy\nevery completed task.'
    ),
  ];

  Future<void> _finishOnboarding() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    await OnboardingView.markCompleted();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => widget.nextPage ?? const MainLayout(),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: context.isDarkMode
                                  ? const [
                                      AppColors.darkElevatedCard,
                                      AppColors.darkCard,
                                    ]
                                  : [
                                      AppColors.warmSand.withOpacity(0.9),
                                      AppColors.softLavender.withOpacity(0.9),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            p.$1,
                            size: 96,
                            color: context.isDarkMode
                                ? AppColors.darkAccentLavender
                                : AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          p.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.$3,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? context.accentColor
                        : (context.isDarkMode
                            ? AppColors.darkBorder
                            : AppColors.warmSand),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _isNavigating
                      ? null
                      : (isLast
                          ? _finishOnboarding
                          : () => _pageCtrl.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              )),
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: _isNavigating ? null : _finishOnboarding,
              child: Text(
                'Skip',
                style: TextStyle(color: context.secondaryTextColor),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}