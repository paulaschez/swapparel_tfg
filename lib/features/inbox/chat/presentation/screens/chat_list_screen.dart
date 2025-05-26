import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../app/config/routes/app_routes.dart';
import '../provider/chat_list_provider.dart';
import '../../../../match/data/models/match_model.dart';
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
    super
        .initState(); // Al ser ChangeNotifierProxyProvider ya se llama a _loadOrClearConversations
  }

  @override
  Widget build(BuildContext context) {
    final chatListProvider = context.watch<ChatListProvider>();
    final authProvider = context.watch<AuthProviderC>();

    if (chatListProvider.isLoading && chatListProvider.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatListProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Error: ${chatListProvider.errorMessage}",
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    if (chatListProvider.conversations.isEmpty && !chatListProvider.isLoading) {
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
      itemCount: chatListProvider.conversations.length,
      separatorBuilder:
          (context, index) => const Divider(
            height: 1,
            indent: 16,
            color: AppColors.primaryGreen,
          ),
      itemBuilder: (context, index) {
        final MatchModel conversation =
            chatListProvider
                .conversations[index]; // TODO: Cambiar a ConversationModel
        String otherUserId = '';
        if (conversation.participantIds.length == 2 &&
            authProvider.currentUserId != null) {
          otherUserId = conversation.participantIds.firstWhere(
            (id) => id != authProvider.currentUserId,
            orElse: () => '',
          );
        }

        String otherUserName = "Usuario del Chat";
        String? otherUserPhotoUrl;

        if (conversation.participantDetails != null &&
            conversation.participantDetails!.containsKey(otherUserId)) {
          otherUserName =
              conversation.participantDetails![otherUserId]!['name'] ??
              'Usuario';
          otherUserPhotoUrl =
              conversation.participantDetails![otherUserId]!['photoUrl'];
        } else {
          // Fallback si no tienes los detalles en MatchModel
          otherUserName =
              "Usuario ${otherUserId.substring(0, 5)}"; // Muestra parte del ID
        }

        final String lastMessage =
            conversation.lastMessageSnippet ?? "Inicia la conversación...";
        // Formatear el timestamp
        final String timeAgo =
            conversation.lastActivityAt != null
                ? timeago.format(
                  conversation.lastActivityAt!.toDate(),
                  locale: 'es',
                ) // Configura el locale
                : "Ahora";

        // TODO: Implementar lógica de unreadCount para el usuario actual en este chat
        final int unreadCountForThisChat =
            conversation.unreadCounts[authProvider.currentUserId] ?? 0;
        final bool hasUnread = unreadCountForThisChat > 0;

        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage:
                otherUserPhotoUrl != null && otherUserPhotoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(otherUserPhotoUrl)
                    : null,
            backgroundColor: Colors.grey[300],
            child:
                (otherUserPhotoUrl == null || otherUserPhotoUrl.isEmpty)
                    ? Icon(Icons.person, color: Colors.white, size: 28)
                    : null,
          ),
          title: Text(
            otherUserName,
            style: TextStyle(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              fontSize: ResponsiveUtils.fontSize(
                context,
                baseSize: 15,
                maxSize: 17,
              ),
            ),
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  hasUnread
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Colors.grey[600],
              fontSize: ResponsiveUtils.fontSize(
                context,
                baseSize: 13,
                maxSize: 15,
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(
                    context,
                    baseSize: 11,
                    maxSize: 12,
                  ),
                  color: hasUnread ? AppColors.primaryGreen : Colors.grey[600],
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(height: 4),
                CircleAvatar(
                  radius: 9,
                  backgroundColor: AppColors.likeRed,
                  child: Text(
                    unreadCountForThisChat.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            print("Navegando al chat con ID: ${conversation.id}");
            context.pushNamed(
              'chatConversation', // Asume que 'chatConversation' es el nombre de tu ruta
              pathParameters: {'chatId': conversation.id},
            );
          },
        );
      },
    );
  }
}
