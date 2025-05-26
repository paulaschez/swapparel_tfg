import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:swapparel/features/inbox/notification/data/models/notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.largeVerticalSpacing(context)),
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(8), 
          border:
              notification.isRead
                  ? null
                  : Border.all(
                    color: AppColors.primaryGreen,
                    width: 1.5,
                  ), // Borde si no está leída
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
       
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize
                        .min,
                children: [
                  Text(
                    notification.displayTitle,
                    style:TextStyle(fontWeight : FontWeight.bold ,fontSize: ResponsiveUtils.fontSize(context, baseSize: 18)) ,
                  ),
                  Text(
                    notification.displayMessage,
                    style: TextStyle(fontSize: ResponsiveUtils.fontSize(context, baseSize: 15)),
                  ),

                  SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                  Text(
                    timeago.format(
                      notification.createdAt.toDate(),
                      locale: 'es',
                    ), 
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(
                        context,
                        baseSize: 12,
                        maxSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveUtils.verticalSpacing(context)),
            if (notification.relatedGarmentImageUrl != null &&
                notification.relatedGarmentImageUrl!.isNotEmpty)
              SizedBox(
                width: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 65,
                  maxSize: 75,
                ), // Ajusta a tu gusto
                child: AspectRatio(
                  aspectRatio: 1, // Relación 1:1
                  child: CachedNetworkImage(
                    imageUrl: notification.relatedGarmentImageUrl!,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}