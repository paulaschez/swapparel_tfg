import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
//import 'package:go_router/go_router.dart'; 
//import '../../../../../app/config/routes/app_routes.dart'; 
// TODO: Importar ChatListProvider (o MatchProvider si los matches son las conversaciones)
// TODO: Importar MatchModel o un ConversationModel
// import '../provider/chat_list_provider.dart';
// import '../../../match/data/models/match_model.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Para avatares
import '../../../../../app/config/theme/app_theme.dart'; // Para AppColors

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {

  @override
  void initState() {
    super.initState();
    // TODO: Llamar al provider para cargar la lista de chats/matches si es necesario
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<ChatListProvider>(context, listen: false).fetchConversations();
    // });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Obtener datos del ChatListProvider
    // final chatListProvider = context.watch<ChatListProvider>();
    // final List<MatchModel> conversations = chatListProvider.conversations; // O MatchModel
    // final bool isLoading = chatListProvider.isLoading;

    // --- DATOS DE EJEMPLO POR AHORA ---
    final bool isLoading = false; // Simular que no está cargando
    final List<Map<String, dynamic>> exampleConversations = [
      {'id': 'match_id_1', 'otherName': 'Charlie Brown', 'otherUserPhotoUrl': 'https://picsum.photos/seed/charlie/50/50', 'lastMessage': '¡Hola! ¿Cuándo quedamos?', 'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 5))), 'unreadCount': 1},
      {'id': 'match_id_2', 'otherName': 'Lucy Van Pelt', 'otherUserPhotoUrl': 'https://picsum.photos/seed/lucy/50/50', 'lastMessage': 'Ok, perfecto.', 'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))), 'unreadCount': 0},
      {'id': 'match_id_3', 'otherName': 'Snoopy', 'otherUserPhotoUrl': null, 'lastMessage': 'Woof woof!', 'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1))), 'unreadCount': 3},
    ];
    // --- FIN DATOS DE EJEMPLO ---


    if (isLoading && exampleConversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (exampleConversations.isEmpty && !isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Aún no tienes conversaciones.\n¡Haz swipe en el feed para encontrar matches!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: exampleConversations.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, color: AppColors.primaryGreen,), // Separador
      itemBuilder: (context, index) {
        final conversation = exampleConversations[index]; // TODO: Cambiar a ConversationModel
        final bool hasUnread = (conversation['unreadCount'] ?? 0) > 0;

        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: conversation['otherUserPhotoUrl'] != null
                ? CachedNetworkImageProvider(conversation['otherUserPhotoUrl']!)
                : null,
            child: conversation['otherUserPhotoUrl'] == null ? const Icon(Icons.person) : null,
          ),
          title: Text(
            conversation['otherName'] ?? 'Usuario',
            style: TextStyle(fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal),
          ),
          subtitle: Text(
            conversation['lastMessage'] ?? '...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: hasUnread ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[600]),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                //TODO: Usar paquete timeago
                (conversation['timestamp'] as Timestamp).toDate().toString().substring(11,16),
                style: TextStyle(
                  fontSize: 12,
                  color: hasUnread ? AppColors.primaryGreen : Colors.grey[600],
                ),
              ),
              if (hasUnread) ...[
                Expanded(
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.likeRed,
                    child: Text(
                      conversation['unreadCount'].toString(),
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ]
            ],
          ),
          onTap: () {
            print("Navegando al chat con ID: ${conversation['id']}");
            // TODO: Navegar al ChatScreen con el ID del chat/match
            // context.push(AppRoutes.chatConversation.replaceFirst(':chatId', conversation['id']!));
          },
        );
      },
    );
  }
}