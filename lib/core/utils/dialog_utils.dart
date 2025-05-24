// lib/core/utils/dialog_utils.dart (o el nombre que prefieras)
import 'package:flutter/material.dart';
import 'package:swapparel/app/config/theme/app_theme.dart'; // Para tus AppColors y tema
import 'package:swapparel/core/utils/responsive_utils.dart'; // Para fuentes responsivas

// Clase contenedora para las opciones de acción del diálogo
class DialogAction {
  final String text;
  final VoidCallback onPressed;
  final bool isDestructive; // Para aplicar estilo diferente (ej: rojo)
  final bool isDefault; // Para aplicar un estilo de "acción principal"

  DialogAction({
    required this.text,
    required this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
  });
}

Future<T?> showAppConfirmationDialog<T>({
  required BuildContext context,
  required String title,
  required String
  content,
  required List<DialogAction> actions,
  bool barrierDismissible =
      false, // Por defecto, no se puede cerrar tocando fuera
}) async {
  // Cerrar teclado si está abierto
  FocusScope.of(context).unfocus();

  return await showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
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
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 12.0,
        ),
        actions:
            actions.map((action) {
              TextStyle buttonTextStyle = TextStyle(
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 14,
                  maxSize: 16,
                ),
                fontWeight:
                    action.isDefault ? FontWeight.bold : FontWeight.normal,
              );
              Color buttonForegroundColor =
                  Theme.of(context).colorScheme.primary;
              if (action.isDestructive) {
                buttonForegroundColor = Theme.of(context).colorScheme.error;
              }

              return TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: buttonForegroundColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  action.onPressed();
                },
                child: Text(action.text, style: buttonTextStyle),
              );
            }).toList(),
      );
    },
  );
}

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
            color: AppColors.darkGreen.withOpacity(0.8),
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
