import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../auth/presentation/provider/auth_provider.dart';
import '../../../../match/data/models/match_model.dart'; // Usaremos MatchModel para las conversaciones
import '../../../../match/data/repositories/match_repository.dart'; // Para getMyMatches

class ChatListProvider extends ChangeNotifier {
  final MatchRepository _matchRepository;
  StreamSubscription? _conversationsSubscription;
  final String? effectiveUserId;

  ChatListProvider({
    required MatchRepository matchRepository,
    required AuthProviderC authProvider,
  }) : _matchRepository = matchRepository,
       effectiveUserId = authProvider.currentUserId {
    print(
      "ChatListProvider created/updated. Current User ID: $effectiveUserId",
    );
    _loadOrClearConversations();
  }

  List<MatchModel> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MatchModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _loadOrClearConversations() {
    final userId = effectiveUserId;

    _conversationsSubscription?.cancel();
    _conversations = [];
    _errorMessage = null;

    if (userId == null || userId.isEmpty) {
      print(
        "ChatListProvider: effectiveUserId is null or empty. Clearing data.",
      );
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    print(
      "ChatListProvider: Subscribing to conversations for effective user $userId",
    );
    _conversationsSubscription = _matchRepository
        .getMyMatches(userId)
        .listen(
          (convos) {
            _conversations = convos;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
            print(
              "ChatListProvider: Conversations RECEIVED for effective user $userId. Count: ${convos.length}",
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


  @override
  void dispose() {
     print("ChatListProvider: DISPOSE CALLED for effectiveUser: $effectiveUserId. Cancelling subscription.");
    _conversationsSubscription?.cancel();
    print("ChatListProvider: Disposed completed");
    super.dispose();
  }
}
