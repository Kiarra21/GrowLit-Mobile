import 'package:flutter/material.dart';
import 'package:growlit_mobile/theme/colors.dart';
import 'package:growlit_mobile/theme/typography.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.fernGreen,
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.fernGreen,
    primary: AppColors.fernGreen,
    secondary: AppColors.resedaGreen,
    error: Colors.red,
    brightness: Brightness.light,
  ),
  fontFamily: 'Poppins',
  textTheme: const TextTheme(
    displayLarge: AppTypography.headline1,
    displayMedium: AppTypography.headline2,
    bodyLarge: AppTypography.bodyText1,
    bodyMedium: AppTypography.bodyText2,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.fernGreen,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.fernGreen,
      foregroundColor: Colors.white,
      textStyle: AppTypography.button,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);
