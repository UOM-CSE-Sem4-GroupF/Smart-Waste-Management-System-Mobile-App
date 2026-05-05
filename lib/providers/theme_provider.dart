import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global theme-mode provider. Starts in dark mode and can be toggled.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
