import 'package:flutter/material.dart';
import 'package:swapparel/core/utils/date_formatter.dart'; 
import '../../../../../app/config/theme/app_theme.dart'; 
import '../../../../../core/utils/responsive_utils.dart'; 
import '../../data/models/message_model.dart'; 

class OutgoingMessageBubble extends StatelessWidget {
  final MessageModel message;

  const OutgoingMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double bubbleMaxWidth = screenSize.width * 0.75;
     final String formattedDate = DateFormatter.formatMessageBubbleTimestamp(message.timestamp);

    return Align(
      alignment: Alignment.centerRight, 
      child: Container(
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
        margin: EdgeInsets.only(
          left: screenSize.width * 0.15, 
          right: ResponsiveUtils.fontSize(context, baseSize: 8, maxSize: 10),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.fontSize(context, baseSize: 12, maxSize: 16),
          vertical: ResponsiveUtils.fontSize(context, baseSize: 8, maxSize: 10),
        ),
        decoration: BoxDecoration(
          color: AppColors.lightGreen, 
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          boxShadow: [ 
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 3,
              offset: const Offset(1, 1),
            )
          ]
        ),
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.end, 
          mainAxisSize: MainAxisSize.min, 
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: AppColors.darkGreen, 
                fontSize: ResponsiveUtils.fontSize(context, baseSize: 15, maxSize: 17),
              ),
            ),
            SizedBox(height: ResponsiveUtils.fontSize(context, baseSize: 3, maxSize: 5)),
            Text(
             formattedDate, 
              style: TextStyle(
                color: AppColors.darkGreen.withValues(alpha:0.7),
                fontSize: ResponsiveUtils.fontSize(context, baseSize: 10, maxSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}