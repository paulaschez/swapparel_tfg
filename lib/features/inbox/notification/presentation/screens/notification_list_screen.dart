import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:swapparel/app/config/routes/app_routes.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:swapparel/features/inbox/notification/presentation/widgets/notification_card.dart';
import '../provider/notification_provider.dart';
import '../../../notification/data/models/notification_model.dart'; //
import 'package:timeago/timeago.dart' as timeago;

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    timeago.setLocaleMessages('es_short', timeago.EsShortMessages());
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();

    if (notificationProvider.isLoading &&
        notificationProvider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notificationProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Error: ${notificationProvider.errorMessage}",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (notificationProvider.notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No tienes notificaciones.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      separatorBuilder:
          (context, index) =>
              SizedBox(height: ResponsiveUtils.largeVerticalSpacing(context)),
      padding: EdgeInsets.all(ResponsiveUtils.verticalSpacing(context)),
      itemCount: notificationProvider.notifications.length,
      itemBuilder: (context, index) {
        final notification = notificationProvider.notifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () {
            if (!notification.isRead) {
              notificationProvider.markAsRead(notification.id);
            }
            // Navegación (adaptar AppRoutes según tu configuración)
            if (notification.type == NotificationType.match &&
                notification.entityId != null) {
              // context.push(AppRoutes.chatConversation.replaceFirst(':chatId', notification.entityId!));
              print("TODO: Nav to chat ${notification.entityId}");
            } else if (notification.type == NotificationType.like &&
                notification.relatedUserId != null) {
              context.push(AppRoutes.profile.replaceFirst(':userId', notification.relatedUserId!));
              print("Navigating to profile ${notification.relatedUserId}");
            } else if (notification.relatedGarmentId != null) {
              // Navegar al detalle de la prenda si es una notificación general sobre una prenda
              // context.push(AppRoutes.garmentDetail.replaceFirst(':garmentId', notification.relatedGarmentId!));
              print(
                "TODO: Nav to garment detail ${notification.relatedGarmentId}",
              );
            }
          },
        );
      },
    );
  }
}
