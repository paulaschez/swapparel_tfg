import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../../auth/presentation/provider/auth_provider.dart';
//import '../../../../auth/data/models/user_model.dart';

class ChatDetailProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final AuthProviderC _authProvider;
  StreamSubscription? _messagesSubscription;

  String _currentChatId = ''; // ID del chat que se está viendo

  ChatDetailProvider({
    required ChatRepository chatRepository,
    required AuthProviderC authProvider,
  }) : _chatRepository = chatRepository,
       _authProvider = authProvider;

  List<MessageModel> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  String? _errorMessage;

  List<MessageModel> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;
  String? get errorMessage => _errorMessage;
  String get currentChatId => _currentChatId;

  void loadMessagesForChat(String chatId) {
    if (chatId.isEmpty) {
      _errorMessage = "ID de chat inválido.";
      notifyListeners();
      return;
    }
    // Si es el mismo chat no hacer nada
    if (_currentChatId == chatId &&
        _messagesSubscription != null &&
        !_isLoadingMessages) {
      print(
        "ChatDetailProvider: Ya suscrito y mostrando mensajes para $chatId",
      );
      return;
    }

    _chatRepository.markMessagesAsRead;
    print("ChatDetailProvider: Cargando mensajes para chat $chatId");

    _currentChatId = chatId;
    _isLoadingMessages = true;
    _messages = []; // Limpiar mensajes anteriores
    _errorMessage = null;
    notifyListeners();

    _messagesSubscription?.cancel(); // Cancelar suscripción anterior
    _messagesSubscription = _chatRepository
        .getChatMessages(
          chatId: _currentChatId,
          limit: 50,
        ) // Cargar más mensajes inicialmente
        .listen(
          (loadedMessages) {
            _messages = loadedMessages;
            _isLoadingMessages = false;
            _errorMessage = null;
            notifyListeners();
            _chatRepository.markMessagesAsRead(
              _currentChatId,
              _authProvider.currentUserId!,
            );
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoadingMessages = false;
            _messages = [];
            notifyListeners();
            print("ChatDetailProvider Error - loadMessages: $error");
          },
        );
  }

  Future<bool> sendMessage(String text) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty ||
        _currentChatId.isEmpty ||
        _authProvider.currentUserId == null ||
        _authProvider.currentUserModel == null) {
      _errorMessage = "No se puede enviar el mensaje. Faltan datos.";
      notifyListeners();
      return false;
    }

    _isSendingMessage = true;
    notifyListeners();

    final String senderId = _authProvider.currentUserId!;

    try {
      await _chatRepository.sendMessage(
        chatId: _currentChatId,
        senderId: senderId,

        text: trimmedText,
      );
      _isSendingMessage = false;
      _errorMessage = null;

      notifyListeners(); // Para actualizar el estado de isSendingMessage y limpiar el error
      return true;
    } catch (e) {
      _errorMessage = "Error al enviar mensaje: ${e.toString()}";
      _isSendingMessage = false;
      notifyListeners();
      return false;
    }
  }

  void clearChatDataAndSubscription() {
    print(
      "ChatDetailProvider: Clearing chat data and subscription for $_currentChatId",
    );

    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _messages = [];
    _currentChatId = '';
    _isLoadingMessages = false;
    _errorMessage = null;
  }

  @override
  void dispose() {
    print("ChatDetailProvider: Disposing - Cancelling messages subscription.");
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
