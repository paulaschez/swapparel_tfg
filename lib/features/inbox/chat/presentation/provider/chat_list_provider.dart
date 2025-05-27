import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../auth/presentation/provider/auth_provider.dart';
import '../../../../match/data/models/match_model.dart'; // Usaremos MatchModel para las conversaciones
import '../../../../match/data/repositories/match_repository.dart'; // Para getMyMatches

class ChatListProvider extends ChangeNotifier {
  final MatchRepository _matchRepository;
  final AuthProviderC _authProvider;
  StreamSubscription? _conversationsSubscription;

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
    final userId = _authProvider.currentUserId;
    if (userId == null || userId.isEmpty) {
      _clearConversationsData();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); 

    _conversationsSubscription?.cancel();
    _conversationsSubscription = _matchRepository
        .getMyMatches(userId)
        .listen(
          (convos) {
            _conversations = convos;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
            print(
              "ChatListProvider: Conversations updated via stream. Count: ${convos.length}",
            );
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            _conversations = [];
            notifyListeners();
            print("ChatListProvider Error - conversations stream: $error");
          },
        );
  }


  void _clearConversationsData() {
    print("ChatListProvider: Clearing conversations data.");
    _conversationsSubscription?.cancel(); // Si usaras un stream
    _conversations = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners(); // Importante notificar para limpiar la UI
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    print("ChatListProvider: Disposed");
    super.dispose();
  }
}
