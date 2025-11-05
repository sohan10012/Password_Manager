// lib/utils/password_generator.dart
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  // Keep the original for backward compatibility
  static String generate({
    required int length,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool avoidAmbiguous = false,
  }) {
    return generateSecurePassword(
      length: length,
      includeUppercase: includeUppercase,
      includeLowercase: includeLowercase,
      includeNumbers: includeNumbers,
      includeSymbols: includeSymbols,
      avoidAmbiguous: avoidAmbiguous,
    );
  }

  static String generateSecurePassword({
    required int length,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool avoidAmbiguous = false,
  }) {
    if (length < 8) throw ArgumentError('Password must be at least 8 characters');
    
    String charset = '';
    List<String> requiredSets = [];

    if (includeLowercase) {
      charset += _lowercase;
      requiredSets.add(_lowercase);
    }
    if (includeUppercase) {
      charset += _uppercase;
      requiredSets.add(_uppercase);
    }
    if (includeNumbers) {
      charset += _digits;
      requiredSets.add(_digits);
    }
    if (includeSymbols) {
      charset += _symbols;
      requiredSets.add(_symbols);
    }

    if (charset.isEmpty) {
      throw ArgumentError('At least one character type must be selected');
    }

    if (avoidAmbiguous) {
      charset = charset.replaceAll(RegExp(r'[0O1lI]'), '');
      for (int i = 0; i < requiredSets.length; i++) {
        requiredSets[i] = requiredSets[i].replaceAll(RegExp(r'[0O1lI]'), '');
      }
    }

    final random = Random.secure();
    List<String> password = [];
    
    for (String set in requiredSets) {
      if (set.isNotEmpty) {
        password.add(set[random.nextInt(set.length)]);
      }
    }

    int remaining = length - password.length;
    for (int i = 0; i < remaining; i++) {
      password.add(charset[random.nextInt(charset.length)]);
    }

    // Shuffle for randomness
    for (int i = password.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      String temp = password[i];
      password[i] = password[j];
      password[j] = temp;
    }

    return password.join('');
  }

  static int calculateStrength(String password) {
    int score = 0;
    int length = password.length;

    if (length >= 12) {
      score += 2;
    } else if (length >= 8) score += 1;

    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(password)) score++;

    if (!RegExp(r'(.)\1{2,}').hasMatch(password)) score++;
    if (!RegExp(r'(123|abc|qwe|asd|password|admin)').hasMatch(password.toLowerCase())) score++;

    return score;
  }

  static String getStrengthLabel(int score) {
    if (score >= 7) return 'Very Strong';
    if (score >= 5) return 'Strong';
    if (score >= 3) return 'Medium';
    return 'Weak';
  }

  static Color getStrengthColor(int score) {
    if (score >= 7) return Colors.green;
    if (score >= 5) return Colors.blue;
    if (score >= 3) return Colors.orange;
    return Colors.red;
  }
}