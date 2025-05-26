import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../app/config/theme/app_theme.dart';
import '../../chat/presentation/screens/chat_list_screen.dart';
import '../../notification/presentation/screens/notification_list_screen.dart';
import '../../notification/presentation/provider/notification_provider.dart';
// import '../provider/chat_list_provider.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 pestañas
    // El badge de notificaciones se debe limpiar al abrir la pestaña directamente??
    /* _tabController.addListener(() {
      if (_tabController.index == 1) { 
         Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
      }
    }); */
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener contadores para los badges (escuchando cambios)
    final unreadNotifications =
        context.watch<NotificationProvider>().unreadCount;
    // final unreadChats = context.watch<ChatListProvider>().unreadChatCount;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,

              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 17,
                  maxSize: 20,
                ),
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 17,
                  maxSize: 20,
                ),
              ),

              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Chats"),
                      // if (unreadChats > 0) ... // Ejemplo de badge para chats
                      //   Padding(
                      //     padding: const EdgeInsets.only(left: 6.0),
                      //     child: CircleAvatar(radius: 4, backgroundColor: AppColors.likeRed),
                      //   ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Notificaciones"),
                      if (unreadNotifications > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: AppColors.likeRed,
                          ), // Badge rojo
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.largeVerticalSpacing(context),),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  // Vista para la pestaña de Chats
                  ChatListScreen(),
                  // Vista para la pestaña de Notificaciones
                  NotificationListScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
