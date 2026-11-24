import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myfirstapp/note_app/cubit/cubit/notes_cubit.dart';
import 'note_app/core/app_theme.dart';
import 'note_app/core/theme_controller.dart';
import 'note_app/models/note_model.dart';
import 'note_app/services/alarm_service.dart';
import 'note_app/views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(NoteModelAdapter());
  await Hive.openBox<NoteModel>(NotesCubit.boxName);
  await AppThemeController.instance.init();

  await AlarmService.instance.init();

  runApp(const NoteFlowApp());
}

class NoteFlowApp extends StatelessWidget {
  const NoteFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotesCubit()..loadNotes(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppThemeController.instance.themeMode,
        builder: (context, mode, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'NoteFlow',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            home: const SplashView(),
          );
        },
      ),
    );
  }
}