import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/core/theme/app_theme.dart';
import 'package:antigravity_gallery/presentation/screens/home_screen.dart';
import 'package:antigravity_gallery/presentation/providers/settings_provider.dart';

class AntigravityApp extends ConsumerWidget {
  const AntigravityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Antigravity Gallery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}