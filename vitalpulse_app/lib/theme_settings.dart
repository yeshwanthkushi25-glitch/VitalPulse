import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(
  ThemeMode.light,
);

Future<void> loadThemePreference() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    appThemeMode.value = preferences.getBool('dark_mode') == true
        ? ThemeMode.dark
        : ThemeMode.light;
  } catch (_) {
    appThemeMode.value = ThemeMode.light;
  }
}

Future<void> setThemeMode(ThemeMode mode) async {
  appThemeMode.value = mode;
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('dark_mode', mode == ThemeMode.dark);
  } catch (_) {
    // The theme still changes for this session if storage is unavailable.
  }
}

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: appThemeMode,
    builder: (context, mode, _) => IconButton(
      tooltip: mode == ThemeMode.dark ? 'Use light mode' : 'Use dark mode',
      onPressed: () => setThemeMode(
        mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      ),
      icon: Icon(
        mode == ThemeMode.dark
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
      ),
    ),
  );
}
