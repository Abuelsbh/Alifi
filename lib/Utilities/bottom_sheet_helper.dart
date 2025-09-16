import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Helper class for displaying modal bottom sheets throughout the application
/// Provides consistent styling and behavior for bottom sheet dialogs
/// Uses theme colors and responsive design for cross-platform compatibility
class BottomSheetHelper{

  /// Displays a modal bottom sheet with consistent styling
  /// Shows content from bottom of screen with rounded top corners
  ///
  /// [context] - Build context for showing the bottom sheet
  /// [widget] - The widget content to display in the bottom sheet
  /// [onDismiss] - Optional callback function when bottom sheet is dismissed
  /// [isDismissible] - Whether the bottom sheet can be dismissed by tapping outside (default: true)
  ///
  /// Returns Future that completes when bottom sheet is dismissed
  static Future bottomSheet({
    required BuildContext context,
    required Widget widget,
    Function? onDismiss,
    double topBorderRadius = 0,
    bool isDismissible = true,
  }) async {
    showModalBottomSheet(
      isDismissible: isDismissible, // Allow dismissal by tapping outside
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(topBorderRadius.r))), // Rounded top corners
      backgroundColor: ThemeClass.of(context).backGroundColor, // Use theme background color
      context: context,
      isScrollControlled: true, // Allow content to control height
      builder: (BuildContext context) => widget, // Build the content widget
    ).then((_) {
      // Execute dismiss callback if provided
      if (onDismiss != null) onDismiss();
    });
  }
}
