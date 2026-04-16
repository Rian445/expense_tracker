import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final box = Hive.box('settings');
    final savedMode = box.get('themeMode', defaultValue: 'light');
    return savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    Hive.box('settings').put('themeMode', state == ThemeMode.dark ? 'dark' : 'light');
  }
}
