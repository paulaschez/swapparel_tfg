import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../auth/presentation/provider/auth_provider.dart';
import '../../../../match/data/models/match_model.dart'; // Usaremos MatchModel para las conversaciones
import '../../../../match/data/repositories/match_repository.dart'; // Para getMyMatches

class ChatListProvider extends ChangeNotifier {
  final MatchRepository _matchRepository;
  final AuthProviderC _authProvider;

  ChatListProvider({
    required MatchRepository matchRepository,
    required AuthProviderC authProvider,
  }) : _matchRepository = matchRepository,
       _authProvider = authProvider {
    print(
      "ChatListProvider created/updated. Current User ID: ${_authProvider.currentUserId}",
    );
    _loadOrClearConversations();
  }

  List<MatchModel> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MatchModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
    AuthProviderC get authProvider => _authProvider;


  void _loadOrClearConversations() {
    if (_authProvider.isAuthenticated && _authProvider.currentUserId != null) {
      fetchConversations(_authProvider.currentUserId!);
    } else {
      _clearConversationsData();
    }
  }

  Future<void> fetchConversations(String userId) async {
    // Evitar recargas si ya está cargando para el mismo usuario
    if (_isLoading &&
        _conversations.isNotEmpty &&
        _authProvider.currentUserId == userId)
      return;

    print("ChatListProvider: Fetching conversations for user $userId");
    _isLoading = true;
    _errorMessage = null;
    // No necesariamente limpiar _conversations aquí si queremos que la UI no parpadee
    // si ya había datos y solo estamos refrescando. Pero para una carga limpia sí.
    // Si este método se llama porque el usuario cambió, _clearConversationsData ya lo hizo.
    if (_conversations.isEmpty)
      notifyListeners(); // Notificar que la carga ha comenzado

    try {
      // Asumimos que getMyMatches es un Future por ahora
      _conversations = await _matchRepository.getMyMatches(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _conversations = [];
      print("ChatListProvider Error - fetchConversations: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearConversationsData() {
    print("ChatListProvider: Clearing conversations data.");
    // _conversationsSubscription?.cancel(); // Si usaras un stream
    _conversations = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners(); // Importante notificar para limpiar la UI
  }

  @override
  void dispose() {
    print("ChatListProvider: Disposed");
    super.dispose();
  }
}
