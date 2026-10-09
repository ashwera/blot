import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

void main() => runApp(const ProviderScope(child: BlotApp()));

class BlotApp extends StatelessWidget {
  const BlotApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Blot',
      theme: appTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false);
}
