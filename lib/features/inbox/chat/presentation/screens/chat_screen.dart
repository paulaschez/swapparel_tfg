import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import '../provider/chat_detail_provider.dart';
import '../widgets/incoming_message_bubble.dart';
import '../widgets/outgoing_message_bubble.dart';
import '../../../../auth/presentation/provider/auth_provider.dart';
import '../../../../../core/utils/responsive_utils.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    this.otherUserId,
  });
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Para auto-scroll

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatDetailProvider = Provider.of<ChatDetailProvider>(
        context,
        listen: false,
      );
      chatDetailProvider.loadMessagesForChat(widget.chatId);
    });
  }

  @override
  void dispose() {
    print("ChatScreen: Disposing...");

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatDetailProvider = Provider.of<ChatDetailProvider>(
      context,
      listen: false,
    );
    bool success = await chatDetailProvider.sendMessage(
      _messageController.text.trim(),
    );

    if (success) {
      _messageController.clear();
      _scrollToBottom(); // Auto-scroll después de enviar
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              chatDetailProvider.errorMessage ?? "Error al enviar mensaje",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    // Da un pequeño respiro para que el ListView se reconstruya con el nuevo mensaje
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatDetailProvider = context.watch<ChatDetailProvider>();
    final authUserId =
        Provider.of<AuthProviderC>(context, listen: false).currentUserId;

    // Escuchar cambios en los mensajes para hacer scroll
    if (chatDetailProvider.messages.isNotEmpty) {
      _scrollToBottom();
    }

    String appBarTitle = widget.otherUserName;
    String? appBarPhotoUrl = widget.otherUserPhotoUrl;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: ResponsiveUtils.fontSize(context, baseSize: 20),
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: ResponsiveUtils.fontSize(
                context,
                baseSize: 18,
                maxSize: 20,
              ),
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  appBarPhotoUrl != null && appBarPhotoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(appBarPhotoUrl)
                      : null,
              child:
                  (appBarPhotoUrl == null || appBarPhotoUrl.isEmpty)
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                appBarTitle,
                style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                  fontSize: ResponsiveUtils.fontSize(
                    context,
                    baseSize: 17,
                    maxSize: 19,
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          print("ChatScreen: Tapped outside TextField, unfocusing.");
        },
        child: Column(
          children: [
            Expanded(
              child:
                  chatDetailProvider.isLoadingMessages &&
                          chatDetailProvider.messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : chatDetailProvider.errorMessage != null &&
                          chatDetailProvider.messages.isEmpty
                      ? Center(
                        child: Text(
                          "Error: ${chatDetailProvider.errorMessage}",
                        ),
                      )
                      : chatDetailProvider.messages.isEmpty
                      ? const Center(
                        child: Text("No hay mensajes aún. ¡Saluda! 👋"),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(10.0),
                        itemCount: chatDetailProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatDetailProvider.messages[index];
                          final bool isMe = message.senderId == authUserId;
                          if (isMe) {
                            return OutgoingMessageBubble(message: message);
                          } else {
                            return IncomingMessageBubble(message: message);
                          }
                        },
                      ),
            ),
            // --- BARRA DE ENTRADA DE MENSAJE ---
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(
                bottom: MediaQuery.of(context).padding.bottom + 8.0,
              ), // Padding para el notch/gestos
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Escribe un mensaje...",

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted:
                          (_) =>
                              _sendMessage(), // Enviar con la tecla Enter del teclado
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 5, 
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true, 
                    onPressed:
                        chatDetailProvider.isSendingMessage
                            ? null
                            : _sendMessage, 
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 2,
                    child:
                        chatDetailProvider.isSendingMessage
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
