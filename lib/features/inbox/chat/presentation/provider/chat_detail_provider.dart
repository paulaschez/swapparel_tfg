import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:swapparel/core/utils/date_formatter.dart';
import 'package:swapparel/features/offer/data/model/offer_model.dart';
import 'package:swapparel/features/offer/data/repositories/offer_repository.dart';
import 'package:swapparel/features/inbox/chat/presentation/screens/chat_screen.dart';
import 'package:swapparel/features/match/data/models/match_model.dart';
import 'package:swapparel/features/match/data/repositories/match_repository.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../../auth/presentation/provider/auth_provider.dart';

class ChatDetailProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final AuthProviderC _authProvider;
  final MatchRepository _matchRepository;
  final OfferRepository _offerRepository;
  final String? effectiveUserId;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _offersSubscription;
  StreamSubscription? _matchSubscription;

  String _currentChatId = ''; // ID del chat que se está viendo

  ChatDetailProvider({
    required ChatRepository chatRepository,
    required AuthProviderC authProvider,
    required MatchRepository matchRepository,
    required OfferRepository offerRepository,
  }) : _chatRepository = chatRepository,
       _authProvider = authProvider,
       _matchRepository = matchRepository,
       _offerRepository = offerRepository,
       effectiveUserId = authProvider.currentUserId {
    print(
      "ChatDetailProvider: INSTANCE CONSTRUCTED for effectiveUser: $effectiveUserId. CurrentChatId: $_currentChatId (debería estar vacío inicialmente)",
    );
  }
  List<ChatTimelineItem> get timelineItems => groupedTimelineItems;
  List<MessageModel> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  String? _errorMessage;

  List<MessageModel> get messages => _messages;
  List<OfferModel> get offersList => _offersList;

  List<OfferModel> _offersList = [];
  MatchModel? _match;
  MatchModel? get match => _match;

  bool _isLoadingMatch = false;
  bool get isLoadingMatch => _isLoadingMatch;

  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;
  String? get errorMessage => _errorMessage;
  String get currentChatId => _currentChatId;

  void initializeChat(String chatId) {
    print(
      "ChatDetailProvider: initializeChat CALLED for chatId: '$chatId', effectiveUser: $effectiveUserId",
    );
    if (_currentChatId == chatId &&
        _messagesSubscription != null &&
        _offersSubscription != null) {
      print(
        "ChatDetailProvider: initializeChat - Already initialized for '$chatId'. Skipping.",
      );
      return;
    }
    _currentChatId = chatId;
    // Limpiar datos anteriores si el chatId cambia o es la primera vez para este provider
    _messages = [];
    _offersList = [];
    _match = null;
    _errorMessage = null;

    loadMessagesForChat(_currentChatId);
    listenToOffers(_currentChatId);
    listenToMatchDetails(_currentChatId);
  }

  void loadMessagesForChat(String chatId) {
    print(
      "ChatDetailProvider: loadMessagesForChat CALLED with chatId: '$chatId', effectiveUser: $effectiveUserId",
    );

    if (chatId.isEmpty || effectiveUserId == null || effectiveUserId!.isEmpty) {
      _errorMessage =
          "Chat ID inválido o usuario no autenticado para cargar mensajes.";
      _isLoadingMessages = false;
      print(
        "ChatDetailProvider: loadMessagesForChat - Invalid params. Error: $_errorMessage",
      );
      notifyListeners();
      return;
    }

    _isLoadingMessages = true;
    notifyListeners();

    _messagesSubscription?.cancel(); // Cancelar suscripción anterior si existía
    print(
      "ChatDetailProvider: loadMessagesForChat - Previous messages subscription (if any) cancelled for '$_currentChatId'.",
    );

    _messagesSubscription = _chatRepository
        .getChatMessages(chatId: chatId, limit: 50)
        .listen(
          (loadedMessages) {
            print(
              "ChatDetailProvider: loadMessagesForChat - MESSAGES RECEIVED for '$chatId'. Count: ${loadedMessages.length}",
            );
            _messages = loadedMessages;
            _isLoadingMessages = false;
            _errorMessage = null;
            notifyListeners();

            if (effectiveUserId != null) {
              print(
                "ChatDetailProvider: loadMessagesForChat - Attempting to mark messages as read for '$chatId', user: '$effectiveUserId'.",
              );
              _chatRepository
                  .markMessagesAsRead(
                    _currentChatId,
                    _authProvider.currentUserId!,
                  )
                  .then((_) {
                    print(
                      "ChatDetailProvider: markMessagesAsRead COMPLETED for '$_currentChatId'.",
                    );
                  })
                  .catchError((e) {
                    print(
                      "ChatDetailProvider: markMessagesAsRead FAILED for '$_currentChatId'. Error: $e",
                    );
                  });
            } else {
              print(
                "ChatDetailProvider: loadMessagesForChat - Cannot mark messages as read, currentUserId is null.",
              );
            }
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoadingMessages = false;
            _messages =
                []; // Asegurarse de que los mensajes estén vacíos en caso de error
            notifyListeners();
            print(
              "ChatDetailProvider: loadMessagesForChat - ERROR loading messages for '$_currentChatId'. Error: $error",
            );
          },
          onDone: () {
            print(
              "ChatDetailProvider: loadMessagesForChat - Stream for '$_currentChatId' is DONE.",
            );
            // No necesariamente un error, pero el stream se cerró.
          },
        );
    print(
      "ChatDetailProvider: loadMessagesForChat - NEW messages subscription CREATED for '$_currentChatId'.",
    );
  }

  void listenToOffers(String matchId) {
    print(
      "ChatDetailProvider: listenToOffers CALLED with matchId: '$matchId', effectiveUser: $effectiveUserId",
    );
    if (matchId.isEmpty ||
        effectiveUserId == null ||
        effectiveUserId!.isEmpty) {
      print(
        "ChatDetailProvider: listenToOffers - Invalid params. Not subscribing.",
      );
      return;
    }

    _offersSubscription?.cancel();
    print(
      "ChatDetailProvider: listenToOffers - Previous offers subscription cancelled for '$matchId'.",
    );

    _offersSubscription = _offerRepository
        .getOfferStreamForMatch(matchId)
        .listen(
          (offers) {
            print(
              "ChatDetailProvider: listenToOffers - OFFERS RECEIVED for '$matchId'. Count: ${offers.length}",
            );
            _offersList = offers;
            notifyListeners();
          },
          onError: (error) {
            print(
              "ChatDetailProvider: listenToOffers - ERROR in offers stream for '$matchId'. Error: $error",
            );
            _offersList = [];
            notifyListeners();
          },
          onDone: () {
            print(
              "ChatDetailProvider: listenToOffers - Stream for '$matchId' is DONE.",
            );
          },
        );
    print(
      "ChatDetailProvider: listenToOffers - NEW offers subscription CREATED for '$matchId'.",
    );
  }

  Future<bool> sendMessage(String text) async {
    final trimmedText = text.trim();
    print(
      "ChatDetailProvider: sendMessage CALLED. Text: '$trimmedText', CurrentChatId: '$_currentChatId', EffectiveUser: $effectiveUserId",
    );

    if (trimmedText.isEmpty ||
        _currentChatId.isEmpty ||
        effectiveUserId == null ||
        effectiveUserId!.isEmpty) {
      _errorMessage =
          "No se puede enviar el mensaje. Faltan datos o usuario no válido.";
      print(
        "ChatDetailProvider: sendMessage - Invalid params. Error: $_errorMessage",
      );
      notifyListeners();
      return false;
    }

    _isSendingMessage = true;
    notifyListeners();
    print("ChatDetailProvider: sendMessage - _isSendingMessage set to TRUE.");

    final String senderId =
        effectiveUserId!; // El que envía es el usuario efectivo de esta instancia
    print("ChatDetailProvider: sendMessage - SenderId: '$senderId'");

    try {
      await _chatRepository.sendMessage(
        chatId: _currentChatId,
        senderId: senderId,
        text: trimmedText,
      );
      print(
        "ChatDetailProvider: sendMessage - _chatRepository.sendMessage SUCCEEDED for '$_currentChatId'.",
      );
      _isSendingMessage = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Error al enviar mensaje: ${e.toString()}";
      _isSendingMessage = false;
      notifyListeners();
      print(
        "ChatDetailProvider: sendMessage - _chatRepository.sendMessage FAILED for '$_currentChatId'. Error: $e",
      );
      return false;
    }
  }

  Future<void> listenToMatchDetails(String matchId) async {
    print(
      "ChatDetailProvider: listenToMatchDetails CALLED for matchId: '$matchId'",
    );
    if (matchId.isEmpty) {
      print(
        "ChatDetailProvider: listenToMatchDetails - Invalid matchId. Not subscribing.",
      );
      _match = null; // Limpiar match si el ID es inválido
      notifyListeners();
      return;
    }

    _isLoadingMatch = true;
    notifyListeners();
    _matchSubscription?.cancel();
    _matchSubscription = _matchRepository
        .getMatchStream(matchId)
        .listen(
          (matchData) {
            print(
              "ChatDetailProvider: listenToMatchDetails - MATCH DATA RECEIVED for '$matchId'. Status: ${matchData?.matchStatus}",
            );
            _match = matchData;
            _isLoadingMatch = false;
            notifyListeners();
          },
          onError: (error) {
            print(
              "ChatDetailProvider: listenToMatchDetails - ERROR in match stream for '$matchId'. Error: $error",
            );
            _errorMessage = "Error al cargar detalles del chat: $error";
            _match = null;
            _isLoadingMatch = false;
            notifyListeners();
          },
        );
    print(
      "ChatDetailProvider: listenToMatchDetails - NEW match subscription CREATED for '$matchId'.",
    );
  }

  List<ChatTimelineItem> get groupedTimelineItems {
    // 1. Combina todas las fuentes de datos en una sola lista de items
    List<ChatTimelineItem> combinedItems = [];

    // Añadir mensajes
    combinedItems.addAll(_messages.map((m) => MessageItem(m)));

    // Añadir ofertas
    combinedItems.addAll(_offersList.map((o) => OfferItem(o)));

    // Añadir la tarjeta de valoración si las condiciones se cumplen
    if (effectiveUserId != null &&
        _match != null &&
        _match!.matchStatus == MatchStatus.completed &&
        _match!.hasUserRated[effectiveUserId] == false &&
        _match!.offerIdThatCompletedMatch != null) {
      final String userToRateId =
          (_match!.participantIds[0] == effectiveUserId)
              ? _match!.participantIds[1]
              : _match!.participantIds[0];
      final String userToRateName =
          _match!.participantDetails?[userToRateId]?['name'] ??
          "el otro usuario";

      combinedItems.add(
        RatingPromptItem(
          matchId: _match!.id,
          offerId: _match!.offerIdThatCompletedMatch!,
          userToRateId: userToRateId,
          userToRateName: userToRateName,
          createdAt: _match!.lastActivityAt ?? _match!.createdAt,
        ),
      );
    }

    // 2. Ordena la lista combinada por fecha
    combinedItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 3. Inserta los separadores de fecha
    if (combinedItems.isEmpty) return [];

    final List<ChatTimelineItem> finalTimeline = [];
    DateTime? lastDate;

    for (final item in combinedItems) {
      final DateTime currentDate = item.createdAt.toDate();

      // Comprueba si es un nuevo día
      if (lastDate == null || !DateFormatter.isSameDay(lastDate, currentDate)) {
        finalTimeline.add(DateSeparatorItem(currentDate));
      }

      // Añade el item original (mensaje, oferta, etc.)
      finalTimeline.add(item);

      // Actualiza la última fecha vista
      lastDate = currentDate;
    }

    return finalTimeline;
  }

  void markRatingGivenForCurrentUser() {
    if (_match != null &&
        effectiveUserId != null &&
        _match!.hasUserRated.containsKey(effectiveUserId!)) {
      final newHasUserRated = Map<String, bool>.from(_match!.hasUserRated);
      newHasUserRated[effectiveUserId!] = true;

      _match = _match!.copyWith(hasUserRated: newHasUserRated);
      print(
        "ChatDetailProvider: markRatingGivenForCurrentUser - Local match updated. Calling _updateTimeline.",
      );
      notifyListeners();
    }
  }

  

  @override
  void dispose() {
    print(
      "ChatDetailProvider: DISPOSE CALLED for effectiveUser: $effectiveUserId, currentChatId: '$_currentChatId'. Cancelling subscriptions.",
    );
    _messagesSubscription?.cancel();
    _offersSubscription?.cancel();
    _matchSubscription?.cancel();
    super.dispose();
    print(
      "ChatDetailProvider: DISPOSE COMPLETED for effectiveUser: $effectiveUserId.",
    );
  }
}
