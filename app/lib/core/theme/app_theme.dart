import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final appTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffef6c45),
        brightness: Brightness.light,
        surface: const Color(0xfffffbf5)),
    scaffoldBackgroundColor: const Color(0xfffff8ef),
    textTheme: GoogleFonts.nunitoTextTheme(),
    useMaterial3: true,
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none)));
