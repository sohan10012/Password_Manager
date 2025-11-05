import 'package:flutter/material.dart'; 
import 'package:password_manager/constants/app_constants.dart';
import 'package:password_manager/theme/theme.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: AppConstants.fontFamily,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: EdgeInsets.all(AppConstants.spacing16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.spacing8),
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: AppConstants.fontFamily,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: Colors.black,
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: EdgeInsets.all(AppConstants.spacing16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.spacing8),
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
    ),
  );
}