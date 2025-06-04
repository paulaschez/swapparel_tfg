import 'package:flutter/material.dart';
import 'package:swapparel/app/config/theme/app_theme.dart'; 
import 'package:swapparel/core/utils/responsive_utils.dart'; 


Future<bool?> showConfirmationDialogFixed({
  required BuildContext context,
  required String title,
  required String content,
  String confirmButtonText = "Confirmar",
  String cancelButtonText = "Cancelar",
  bool isDestructiveAction = false,
}) async {
  FocusScope.of(context).unfocus();
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.lightGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.fontSize(
              context,
              baseSize: 18,
              maxSize: 22,
            ),
            color: AppColors.darkGreen,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(
              context,
              baseSize: 15,
              maxSize: 17,
            ),
            color: AppColors.darkGreen.withValues(alpha: 0.8),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
        actions: <Widget>[
          TextButton(
            child: Text(
              cancelButtonText,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 14,
                  maxSize: 16,
                ),
              ),
            ),
            onPressed:
                () => Navigator.of(dialogContext).pop(false), // Devuelve false
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor:
                  isDestructiveAction
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              confirmButtonText,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 14,
                  maxSize: 16,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed:
                () => Navigator.of(dialogContext).pop(true), // Devuelve true
          ),
        ],
      );
    },
  );
}
