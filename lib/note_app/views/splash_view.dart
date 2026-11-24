import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'onboarding_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingView()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = context.accentColor;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkElevatedCard
                    : AppColors.warmSand.withOpacity(0.55),
                borderRadius: BorderRadius.circular(24),
                border: isDark ? Border.all(color: AppColors.darkBorder) : null,
              ),
              child: Icon(Icons.edit_note_rounded,
                  size: 64,
                  color: isDark ? AppColors.darkAccentLavender : accent),
            ),
            const SizedBox(height: 18),
            Text(
              'NoteFlow',
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800, color: accent),
            ),
            const SizedBox(height: 6),
            Text('Get Things Done',
                style:
                    TextStyle(fontSize: 15, color: context.secondaryTextColor)),
            const SizedBox(height: 44),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: isDark ? AppColors.darkAccentLavender : AppColors.slateBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
