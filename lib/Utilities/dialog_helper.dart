
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Helper class for displaying dialogs throughout the application
/// Provides consistent dialog styling and behavior with theme integration
/// Supports custom dialogs with slide-up animations and rounded corners
class DialogHelper {
  /// Build context for showing dialogs
  final BuildContext context;

  /// Optional message to display in dialogs
  final String? message;

  /// Optional title for dialogs
  final String? title;

  /// Constructor for creating dialog helper with context and optional content
  ///
  /// [context] - Build context for showing dialogs
  /// [message] - Optional message text
  /// [title] - Optional title text
  DialogHelper({required this.context, this.message, this.title});

  /// Factory constructor for creating dialog helper with only context
  /// Used when custom dialog content will be provided separately
  ///
  /// [context] - Build context for showing dialogs
  factory DialogHelper.custom({required BuildContext context}) {
    return DialogHelper(context: context);
  }

  // MARK: - Placeholder Methods (To be implemented)

  /// Shows a success dialog (placeholder for future implementation)
  Future successDialog() async {}

  /// Shows a delete confirmation dialog (placeholder for future implementation)
  ///
  /// [warningMessage] - Warning message to display
  /// [confirmDelete] - Function to execute on delete confirmation
  /// [cancel] - Optional function to execute on cancel
  Future deleteDialog(
      {required warningMessage,
      required Function() confirmDelete,
      Function()? cancel}) async {}

  /// Shows an edit dialog (placeholder for future implementation)
  Future editDialog() async {}

  /// Shows an error dialog (placeholder for future implementation)
  ///
  /// [onTapOk] - Optional function to execute when OK is tapped
  Future errorDialog({
    Function()? onTapOk,
  }) async {}

  // MARK: - Custom Dialog Implementation

  /// Displays a custom dialog with slide-up animation and rounded corners
  /// Provides flexible dialog content with consistent styling
  ///
  /// [dialogWidget] - The widget content to display in the dialog
  /// [dismiss] - Whether dialog can be dismissed by tapping outside (default: true)
  /// [radius] - Optional custom border radius (default: 32.r)
  void customDialog(
      {required Widget dialogWidget, bool dismiss = true, double? radius}) {
    showGeneralDialog(
      useRootNavigator: true, // Use root navigator for proper dialog display
      barrierLabel: "", // Accessibility label for barrier
      context: context,
      barrierDismissible: dismiss, // Allow dismissal by tapping outside
      transitionDuration:
          const Duration(milliseconds: 300), // Animation duration
      transitionBuilder: (context, anim1, anim2, child) {
        // Slide-up animation from bottom
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
              .animate(anim1),
          child: child,
        );
      },
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius ?? 32.r), // Rounded top corners
                  bottom:
                      Radius.circular(radius ?? 32.r) // Rounded bottom corners
                  )),
          backgroundColor:
              ThemeClass.of(context).backGroundColor, // Use theme white color
          insetPadding: EdgeInsets.symmetric(
              horizontal: 24.w, vertical: 24.h), // Responsive padding
          child: dialogWidget, // Custom dialog content
        );
      },
    );
  }

  /// Displays a custom dialog with slide-up animation and rounded corners
  /// Returns a Future that resolves with the dialog result
  ///
  /// [dialogWidget] - The widget content to display in the dialog
  /// [dismiss] - Whether dialog can be dismissed by tapping outside (default: true)
  /// [radius] - Optional custom border radius (default: 32.r)
  Future<T?> customDialogWithResult<T>(
      {required Widget dialogWidget, bool dismiss = true, double? radius}) {
    return showGeneralDialog<T>(
      useRootNavigator: true, // Use root navigator for proper dialog display
      barrierLabel: "", // Accessibility label for barrier
      context: context,
      barrierDismissible: dismiss, // Allow dismissal by tapping outside
      transitionDuration:
          const Duration(milliseconds: 300), // Animation duration
      transitionBuilder: (context, anim1, anim2, child) {
        // Slide-up animation from bottom
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
              .animate(anim1),
          child: child,
        );
      },
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius ?? 32.r), // Rounded top corners
                  bottom:
                      Radius.circular(radius ?? 32.r) // Rounded bottom corners
                  )),
          backgroundColor:
              ThemeClass.of(context).backGroundColor, // Use theme white color
          insetPadding: EdgeInsets.symmetric(
              horizontal: 24.w, vertical: 24.h), // Responsive padding
          child: dialogWidget, // Custom dialog content
        );
      },
    );
  }
}
