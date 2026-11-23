import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'login_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warmSand.withOpacity(0.55),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.edit_note_rounded, size: 64, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 18),
            const Text(
              'NoteFlow',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Get Things Done',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 44),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.slateBlue),
            ),
          ],
        ),
      ),
    );
  }
}