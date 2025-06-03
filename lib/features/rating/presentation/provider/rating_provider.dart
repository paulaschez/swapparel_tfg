import 'package:flutter/foundation.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart'; // Para obtener el ratingUserId
import 'package:swapparel/features/inbox/chat/presentation/provider/chat_detail_provider.dart'; // Para notificar que se ha valorado
import '../../data/models/rating_model.dart';
import '../../data/repositories/rating_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class RatingProvider extends ChangeNotifier {
  final RatingRepository _ratingRepository;
  final AuthProviderC _authProvider; 
  ChatDetailProvider? _chatDetailProvider;

  RatingProvider({
    required RatingRepository ratingRepository,
    required AuthProviderC authProvider,
  }) : _ratingRepository = ratingRepository,
       _authProvider = authProvider;

  void setChatDetailProvider(ChatDetailProvider provider) {
    _chatDetailProvider = provider;
  }

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  AuthProviderC get authProvider => _authProvider;

  Future<bool> submitRating({
    required String matchId,
    required String offerId,
    required String ratedUserId, 
    required double stars,
    String? comment,
    String? ratedUserName
  }) async {
    final String? ratingUserId = _authProvider.currentUserId;
    final String? ratingUserName = _authProvider.currentUserModel?.name;

    if (ratingUserId == null) {
      _errorMessage = "Usuario no autenticado.";
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final rating = RatingModel(
      id: '', 
      matchId: matchId,
      offerId: offerId,
      ratingUserId: ratingUserId,
      ratedUserId: ratedUserId,
      ratedUserName: ratedUserName,
      ratingUserName: ratingUserName ,
      stars: stars,
      comment: comment,
      createdAt: Timestamp.now(),
    );

    try {
      await _ratingRepository.submitRating(rating);
      _isSubmitting = false;
      _chatDetailProvider
          ?.markRatingGivenForCurrentUser(); 
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
