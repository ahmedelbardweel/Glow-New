import 'package:flutter/material.dart';

import 'core/widgets/character_studio_screen.dart';

/// Standalone preview: flutter run -t lib/character_studio_main.dart
/// No account, backend initialization, or network assets are required.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Glow — استوديو الشخصية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF277A59)),
        scaffoldBackgroundColor: const Color(0xFFF3F7F3),
      ),
      home: const CharacterStudioScreen(),
    ),
  );
}
