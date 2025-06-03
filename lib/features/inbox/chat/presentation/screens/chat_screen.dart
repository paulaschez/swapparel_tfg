import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/features/inbox/chat/data/models/message_model.dart';
import 'package:swapparel/features/offer/data/model/offer_model.dart';
import 'package:swapparel/features/offer/presentation/provider/offer_provider.dart';
import 'package:swapparel/features/offer/presentation/widgets/offer_card.dart';
import 'package:swapparel/features/rating/presentation/widgets/rating_prompt_card.dart';
import 'package:swapparel/features/match/data/models/match_model.dart';
import '../provider/chat_detail_provider.dart';
import '../widgets/incoming_message_bubble.dart';
import '../widgets/outgoing_message_bubble.dart';
import '../../../../auth/presentation/provider/auth_provider.dart';
import '../../../../../core/utils/responsive_utils.dart';
import 'package:collection/collection.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    print("ChatScreen (${widget.chatId}): initState CALLED");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(
        "ChatScreen (${widget.chatId}): initState - addPostFrameCallback EXECUTING",
      );
      final chatDetailProvider = Provider.of<ChatDetailProvider>(
        context,
        listen: false,
      );

      print(
        "ChatScreen (${widget.chatId}): Calling provider.initializeChat with chatId: ${widget.chatId}",
      );
      chatDetailProvider.initializeChat(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
    print("ChatScreen (${widget.chatId}): dispose COMPLETED");
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty) {
      return;
    }

    final chatDetailProvider = Provider.of<ChatDetailProvider>(
      context,
      listen: false,
    );
    bool success = await chatDetailProvider.sendMessage(messageText);

    if (success) {
      _messageController.clear();
      _scrollToBottom();
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

  String _getOtherUserId(MatchModel match, String currentUserId) {
    if (match.participantIds.isEmpty || match.participantIds.length < 2) {
      print(
        "ChatScreen (${widget.chatId}): _getOtherUserId - ERROR: Not enough participants in match. Returning empty or first ID.",
      );
      return match.participantIds.isNotEmpty
          ? match.participantIds[0]
          : ''; // O manejar el error de otra forma
    }
    if (match.participantIds[0] == currentUserId) {
      return match.participantIds[1];
    } else {
      return match.participantIds[0];
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      } else {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatDetailProvider = context.watch<ChatDetailProvider>();
    final authUserId =
        Provider.of<AuthProviderC>(context, listen: false).currentUserId;

    if (chatDetailProvider.messages.isNotEmpty) {
      print(
        "ChatScreen (${widget.chatId}): build - Last message text (if any): '${chatDetailProvider.messages.last.text}'",
      );
    }

    String appBarTitle = widget.otherUserName;
    String? appBarPhotoUrl = widget.otherUserPhotoUrl;

    final MatchModel? currentMatch = chatDetailProvider.match;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: ResponsiveUtils.fontSize(context, baseSize: 20),
          ),
          onPressed: () {
            context.pop();
          },
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
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ),
        actions: [
          if (authUserId != null &&
              currentMatch != null &&
              currentMatch.matchStatus == MatchStatus.active)
            TextButton(
              onPressed: () async {
                final String actualOtherUserId = _getOtherUserId(
                  currentMatch,
                  authUserId,
                );

                final List<OfferModel> allOffersForMatch =
                    chatDetailProvider.offersList;

                final OfferModel? existingPendingOffer = allOffersForMatch
                    .firstWhereOrNull(
                      (offer) =>
                          offer.offeringUserId == authUserId &&
                          offer.status == OfferStatus.pending,
                    );

                if (existingPendingOffer != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Ya tienes una oferta pendiente para este chat.",
                      ),
                    ),
                  );
                  return;
                } else {
                  print(
                    "ChatScreen (${widget.chatId}): Proponer Swap - No existing PENDING offer by current user found.",
                  );
                }

                final Map<String, String?>? otherUserDetailsFromMatch =
                    currentMatch.participantDetails?[actualOtherUserId];
                final String? otherUsernameForOffer =
                    otherUserDetailsFromMatch?['name'];

                if (actualOtherUserId.isEmpty) {
                  print(
                    "ChatScreen (${widget.chatId}): Proponer Swap - ERROR: actualOtherUserId is empty. Cannot proceed.",
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error al identificar al otro usuario."),
                    ),
                  );
                  return;
                }

                print(
                  "ChatScreen (${widget.chatId}): Proponer Swap - Navigating to 'createOffer'. matchId: ${widget.chatId}, offeringUserId: $authUserId, receivingUserId: $actualOtherUserId, receivingUsername: $otherUsernameForOffer",
                );
                context.pushNamed(
                  'createOffer',
                  pathParameters: {'matchId': widget.chatId},
                  extra: {
                    'offeringUserId': authUserId,
                    'receivingUserId': actualOtherUserId, 
                    'receivingUsername': otherUsernameForOffer,
                  },
                );
              },
              child: Text(
                "Proponer Swap",
                style: TextStyle(
                  color:
                      Theme.of(context).appBarTheme.actionsIconTheme?.color ??
                      AppColors.darkGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.fontSize(
                    context,
                    baseSize: 15,
                    maxSize: 17,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          print(
            "ChatScreen (${widget.chatId}): Tapped outside TextField, unfocusing.",
          );
        },
        child: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  // Usar Builder para el log de mensajes
                  if (chatDetailProvider.isLoadingMessages &&
                      chatDetailProvider.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (chatDetailProvider.errorMessage != null &&
                      chatDetailProvider.messages.isEmpty) {
                    return Center(
                      child: Text("Error: ${chatDetailProvider.errorMessage}"),
                    );
                  } else if (chatDetailProvider.messages.isEmpty) {
                    return const Center(
                      child: Text("No hay mensajes aún. ¡Saluda! 👋"),
                    );
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scrollToBottom(),
                    );
                    return ListView.separated(
                      separatorBuilder:
                          (context, index) => SizedBox(
                            height: ResponsiveUtils.largeVerticalSpacing(
                              context,
                            ),
                          ),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(10.0),
                      itemCount: chatDetailProvider.timelineItems.length,
                      itemBuilder: (context, index) {
                        final item = chatDetailProvider.timelineItems[index];

                        if (item is MessageItem) {
                          final message = item.message;
                          final bool isMe = message.senderId == authUserId;
                          if (isMe) {
                            return OutgoingMessageBubble(message: message);
                          } else {
                            return IncomingMessageBubble(message: message);
                          }
                        } else if (item is OfferItem) {
                          final offer = item.offer;
                          return OfferCardInChat(
                            offer: offer,
                            currentUserId:
                                authUserId!, 
                            onAccept: (OfferModel offerToAccept) {
                              print(
                                "ChatScreen: Aceptando oferta ${offerToAccept.id}",
                              );
                              context.read<OfferProvider>().respondToOffer(
                                matchId:
                                    offerToAccept.matchId, 
                                offer: offerToAccept,
                                accepted: true,
                              );
                            },
                            onDecline: (OfferModel offerToDecline) {
                              print(
                                "ChatScreen: Rechazando oferta ${offerToDecline.id}",
                              );
                              context.read<OfferProvider>().respondToOffer(
                                matchId:
                                    offerToDecline.matchId, 
                                offer: offerToDecline,
                                accepted: false,
                              );
                            },
                          );
                        } else if (item is RatingPromptItem) {
                       
                          return RatingPromptCard(
                            matchId: item.matchId,
                            offerId: item.offerId,
                            ratingUserId:
                                authUserId!, 
                            userToRateId: item.userToRateId,
                            userToRateName: item.userToRateName,
                          );
                        }
                        return const SizedBox.shrink(); 
                      },
                    );
                  }
                },
              ),
            ),

            // --- BARRA DE ENTRADA DE MENSAJE ---
            Padding(
              padding: const EdgeInsets.all(
                8.0,
              ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Escribe un mensaje...",
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) {
                        print(
                          "ChatScreen (${widget.chatId}): TextField onSubmitted.",
                        );
                        _sendMessage();
                      },
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

abstract class ChatTimelineItem {
  final Timestamp createdAt;
  ChatTimelineItem(this.createdAt);
}

class MessageItem extends ChatTimelineItem {
  final MessageModel message;
  MessageItem(this.message)
    : super(message.timestamp);
}

class OfferItem extends ChatTimelineItem {
  final OfferModel offer;
  OfferItem(this.offer) : super(offer.createdAt);
}

class RatingPromptItem extends ChatTimelineItem {
  final String matchId;
  final String offerId;
  final String userToRateId;
  final String userToRateName;
  RatingPromptItem({
    required this.matchId,
    required this.offerId,
    required this.userToRateId,
    required this.userToRateName,
    required Timestamp
    createdAt, 
  }) : super(createdAt);
}
