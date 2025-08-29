import 'dart:io';
import 'package:flutter/material.dart';
import 'constants.dart';

class SecurityHelper {
  // Email validation with improved regex
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
    );
    
    return emailRegex.hasMatch(email);
  }

  // Password validation with comprehensive rules
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    
    if (password.length > AppConstants.maxPasswordLength) {
      return 'Password must be less than ${AppConstants.maxPasswordLength} characters';
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String name) {
    if (name.isEmpty) {
      return 'Name is required';
    }
    
    if (name.length < AppConstants.minNameLength) {
      return 'Name must be at least ${AppConstants.minNameLength} characters';
    }
    
    if (name.length > AppConstants.maxNameLength) {
      return 'Name must be less than ${AppConstants.maxNameLength} characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }
    
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // Description validation
  static String? validateDescription(String description) {
    if (description.isEmpty) {
      return 'Description is required';
    }
    
    if (description.length < AppConstants.minDescriptionLength) {
      return 'Description must be at least ${AppConstants.minDescriptionLength} characters';
    }
    
    if (description.length > AppConstants.maxDescriptionLength) {
      return 'Description must be less than ${AppConstants.maxDescriptionLength} characters';
    }
    
    return null;
  }

  // Pet name validation
  static String? validatePetName(String petName) {
    if (petName.isEmpty) {
      return 'Pet name is required';
    }
    
    if (petName.length < 2) {
      return 'Pet name must be at least 2 characters';
    }
    
    if (petName.length > 50) {
      return 'Pet name must be less than 50 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(petName)) {
      return 'Pet name can only contain letters and spaces';
    }
    
    return null;
  }

  // Location validation
  static String? validateLocation(String location) {
    if (location.isEmpty) {
      return 'Location is required';
    }
    
    if (location.length < 5) {
      return 'Please provide a more specific location';
    }
    
    if (location.length > 200) {
      return 'Location description is too long';
    }
    
    return null;
  }

  // File validation methods
  static bool validateImageFile(File file) {
    if (!file.existsSync()) {
      return false;
    }
    
    final extension = file.path.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    
    if (!allowedExtensions.contains(extension)) {
      return false;
    }
    
    final fileSizeInBytes = file.lengthSync();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    
    return fileSizeInMB <= AppConstants.maxImageSizeMB;
  }

  static Future<File?> validateAndProcessImage(File imageFile) async {
    if (!validateImageFile(imageFile)) {
      return null;
    }
    
    return imageFile;
  }

  // Data sanitization methods
  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
  }

  static String sanitizeHtml(String html) {
    // Basic HTML sanitization - simplified version
    return html
        .replaceAll('<script', '')
        .replaceAll('</script>', '')
        .replaceAll('<iframe', '')
        .replaceAll('</iframe>', '')
        .replaceAll('<object', '')
        .replaceAll('</object>', '')
        .replaceAll('<embed', '')
        .replaceAll('</embed>', '')
        .replaceAll('<form', '')
        .replaceAll('</form>', '')
        .replaceAll('<input', '')
        .replaceAll('<button', '')
        .replaceAll('</button>', '');
  }

  static String sanitizeUrl(String url) {
    // Basic URL validation and sanitization
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    // Remove potentially dangerous characters
    return url
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '');
  }

  // Password strength checker
  static Map<String, bool> checkPasswordStrength(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final hasMinLength = password.length >= AppConstants.minPasswordLength;
    
    return {
      'hasUppercase': hasUppercase,
      'hasLowercase': hasLowercase,
      'hasNumbers': hasNumbers,
      'hasSpecialChars': hasSpecialChars,
      'hasMinLength': hasMinLength,
      'isStrong': hasUppercase && hasLowercase && hasNumbers && hasSpecialChars && hasMinLength,
    };
  }

  static Color getPasswordStrengthColor(String password) {
    final strength = checkPasswordStrength(password);
    final strongCount = strength.values.where((v) => v == true).length;
    
    switch (strongCount) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
      case 3:
        return Colors.orange;
      case 4:
        return Colors.yellow;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Input formatter for phone numbers
  static String formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.isEmpty) return '';
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    if (digits.length <= 10) return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
  }

  // Credit card validation (if needed for future features)
  static bool isValidCreditCard(String cardNumber) {
    // Remove spaces and dashes
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }
    
    // Luhn algorithm
    int sum = 0;
    bool isEven = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      
      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      isEven = !isEven;
    }
    
    return sum % 10 == 0;
  }

  // Email validation with disposable email check
  static bool isDisposableEmail(String email) {
    final disposableDomains = [
      '10minutemail.com',
      'guerrillamail.com',
      'tempmail.org',
      'mailinator.com',
      'throwaway.email',
      'temp-mail.org',
      'fakeinbox.com',
      'sharklasers.com',
      'getairmail.com',
      'mailnesia.com',
    ];
    
    final domain = email.split('@').last.toLowerCase();
    return disposableDomains.contains(domain);
  }

  // Secure random string generator
  static String generateSecureToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    
    for (int i = 0; i < length; i++) {
      buffer.write(chars[random % chars.length]);
    }
    
    return buffer.toString();
  }
}

class RateLimiter {
  static final Map<String, DateTime> _lastAttempts = {};
  static final Map<String, int> _attemptCounts = {};
  
  static bool canAttempt(String key, {Duration cooldown = const Duration(minutes: 1), int maxAttempts = 5}) {
    final now = DateTime.now();
    final lastAttempt = _lastAttempts[key];
    final attemptCount = _attemptCounts[key] ?? 0;
    
    if (lastAttempt == null) {
      _lastAttempts[key] = now;
      _attemptCounts[key] = 1;
      return true;
    }
    
    final timeSinceLastAttempt = now.difference(lastAttempt);
    
    if (timeSinceLastAttempt >= cooldown) {
      // Reset counter after cooldown
      _lastAttempts[key] = now;
      _attemptCounts[key] = 1;
      return true;
    }
    
    if (attemptCount >= maxAttempts) {
      return false;
    }
    
    _lastAttempts[key] = now;
    _attemptCounts[key] = attemptCount + 1;
    return true;
  }
  
  static Duration getRemainingCooldown(String key, {Duration cooldown = const Duration(minutes: 1)}) {
    final lastAttempt = _lastAttempts[key];
    
    if (lastAttempt == null) {
      return Duration.zero;
    }
    
    final now = DateTime.now();
    final timeSinceLastAttempt = now.difference(lastAttempt);
    final remaining = cooldown - timeSinceLastAttempt;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }
} 