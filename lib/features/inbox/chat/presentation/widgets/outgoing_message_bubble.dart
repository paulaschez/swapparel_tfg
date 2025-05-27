// lib/features/inbox/chat/presentation/widgets/outgoing_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear el timestamp
import '../../../../../app/config/theme/app_theme.dart'; // Para AppColors
import '../../../../../core/utils/responsive_utils.dart'; // Para fuentes
import '../../data/models/message_model.dart'; // Importa tu MessageModel

class OutgoingMessageBubble extends StatelessWidget {
  final MessageModel message;

  const OutgoingMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Máximo ancho de la burbuja (ej: 70-75% del ancho de pantalla)
    final double bubbleMaxWidth = screenSize.width * 0.75;

    return Align(
      alignment: Alignment.centerRight, // Alinea la burbuja a la derecha
      child: Container(
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth), // Limita el ancho
        margin: EdgeInsets.only(
          top: ResponsiveUtils.fontSize(context, baseSize: 4, maxSize: 6),
          bottom: ResponsiveUtils.fontSize(context, baseSize: 4, maxSize: 6),
          left: screenSize.width * 0.15, // Margen izquierdo para empujarlo
          right: ResponsiveUtils.fontSize(context, baseSize: 8, maxSize: 10),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.fontSize(context, baseSize: 12, maxSize: 16),
          vertical: ResponsiveUtils.fontSize(context, baseSize: 8, maxSize: 10),
        ),
        decoration: BoxDecoration(
          color: AppColors.lightGreen, // <--- TU COLOR PARA MENSAJES SALIENTES
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          boxShadow: [ // Sombra sutil opcional
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(1, 1),
            )
          ]
        ),
        child: Column( // Para poner el texto y debajo el timestamp
          crossAxisAlignment: CrossAxisAlignment.end, // Alinea el timestamp a la derecha
          mainAxisSize: MainAxisSize.min, // Para que la columna tome el tamaño del contenido
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: AppColors.darkGreen, // Texto oscuro sobre fondo claro
                fontSize: ResponsiveUtils.fontSize(context, baseSize: 15, maxSize: 17),
              ),
            ),
            SizedBox(height: ResponsiveUtils.fontSize(context, baseSize: 3, maxSize: 5)),
            Text(
              DateFormat('HH:mm').format(message.timestamp.toDate()), // Formato HH:mm
              style: TextStyle(
                color: AppColors.darkGreen.withOpacity(0.7),
                fontSize: ResponsiveUtils.fontSize(context, baseSize: 10, maxSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}