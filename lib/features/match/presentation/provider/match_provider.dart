import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp
import 'package:swapparel/features/auth/data/models/user_model.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/feed/data/repositories/feed_repository.dart';
import 'package:swapparel/features/garment/data/models/garment_model.dart';
import 'package:swapparel/features/match/data/models/match_model.dart';
import 'package:swapparel/features/match/data/repositories/match_repository.dart';
import 'package:swapparel/features/inbox/notification/data/models/notification_model.dart';
import 'package:swapparel/features/inbox/notification/data/repositories/notification_repository.dart';
import 'package:swapparel/features/profile/data/repositories/profile_repository.dart';

class MatchProvider extends ChangeNotifier {
  final AuthProviderC _authProvider;
  final FeedRepository _feedRepository;
  final ProfileRepository _profileRepository;
  final MatchRepository _matchRepository;
  final NotificationRepository _notificationRepository;

  MatchProvider({
    required AuthProviderC authProvider,
    required FeedRepository feedRepository,
    required ProfileRepository profileRepository,
    required MatchRepository matchRepository,
    required NotificationRepository notificationRepository,
  }) : _authProvider = authProvider,
       _feedRepository = feedRepository,
       _profileRepository = profileRepository,
       _matchRepository = matchRepository,
       _notificationRepository = notificationRepository;

  bool _isProcessingLike = false;
  String? _matchErrorMessage;
  MatchModel? _lastCreatedMatch;
  bool _showMatchFeedback = false;

  bool get isProcessingLike => _isProcessingLike;
  String? get matchErrorMessage => _matchErrorMessage;
  MatchModel? get lastCreatedMatch => _lastCreatedMatch;
  bool get showMatchFeedback => _showMatchFeedback;

  /// Maneja la acción de "like" de una prenda, incluyendo la comprobación de match y notificaciones.
  /// Devuelve true si la acción de like fue exitosa (independientemente de si hubo match).
  Future<bool> handleLikeGarment({required GarmentModel likedGarment}) async {
    if (_authProvider.currentUserId == null ||
        _authProvider.currentUserModel == null) {
      _matchErrorMessage = "Usuario no autenticado.";
      notifyListeners();
      return false;
    }
    if (likedGarment.ownerId == _authProvider.currentUserId) {
      _matchErrorMessage = "No puedes dar 'like' a tu propia prenda.";
      notifyListeners();
      return false;
    }

    _isProcessingLike = true;
    _matchErrorMessage = null;
    _lastCreatedMatch = null;
    _showMatchFeedback = false;

    final String currentUserId = _authProvider.currentUserId!;
    final UserModel currentUserModel = _authProvider.currentUserModel!;

    try {
      // 1. Registrar el like en el repositorio de feed (colección global de likes)
      await _feedRepository.likeGarment(
        likerUserId: currentUserId,
        likedGarmentId: likedGarment.id,
        likedGarmentOwnerId: likedGarment.ownerId,
      );

      // 2. Persistir el like en el perfil del usuario actual
      await _profileRepository.addLikedGarmentToMyProfile(
        currentUserId: currentUserId,
        likedGarmentId: likedGarment.id,
      );

      // 3. Notificar al dueño de la prenda sobre el like
      final likeNotification = NotificationModel(
        id: '', // Firestore generará el ID
        recipientId: likedGarment.ownerId,
        type: NotificationType.like,
        relatedUserId: currentUserId,
        relatedUserName: currentUserModel.atUsernameHandle,
        relatedUserPhotoUrl: currentUserModel.photoUrl,
        relatedGarmentId: likedGarment.id,
        relatedGarmentName: likedGarment.name,
        relatedGarmentImageUrl:
            likedGarment.imageUrls.isNotEmpty
                ? likedGarment.imageUrls[0]
                : null,
        entityId: likedGarment.id, // ID de la prenda likeada
        createdAt: Timestamp.now(),
      );
      await _notificationRepository.createNotification(likeNotification);

      // 4. Comprobar si hay match y notificar si ocurre
      final MatchModel? matchResult = await _matchRepository
          .checkForMatchAndNotify(
            likerUserId: currentUserId,
            likedGarmentOwnerId: likedGarment.ownerId,
            likedGarmentId: likedGarment.id,
            likerUsername: currentUserModel.atUsernameHandle,
            likerPhotoUrl: currentUserModel.photoUrl,
            likedGarmentOwnerUsername: likedGarment.ownerUsername,
          );

      if (matchResult != null) {
        _lastCreatedMatch = matchResult;
        _showMatchFeedback = true;
        print(
          "MatchProvider: ¡MATCH CREADO Y NOTIFICADO! ID: ${matchResult.id}",
        );
      }

      _isProcessingLike = false;
      notifyListeners();
      return true; // Like exitoso
    } catch (e) {
      _matchErrorMessage = "Error al procesar el like: ${e.toString()}";
      print("MatchProvider Error - handleLikeGarment: $e");
      _isProcessingLike = false;
      _showMatchFeedback = false;
      notifyListeners();
      return false; // Like fallido
    }
  }

  /// Maneja la acción de "unlike" de una prenda.
  Future<bool> handleUnlikeGarment({
    required GarmentModel unlikedGarment,
  }) async {
    if (_authProvider.currentUserId == null) {
      _matchErrorMessage = "Usuario no autenticado.";
      notifyListeners();
      return false;
    }

    final String currentUserId = _authProvider.currentUserId!;
    try {
      // 1. Quitar de la colección global de likes
      await _feedRepository.removeLikeFromGlobalCollection(
        likerUserId: currentUserId,
        likedGarmentId: unlikedGarment.id,
      );

      // 2. Quitar del perfil del usuario
      await _profileRepository.removeLikedGarmentFromMyProfile(
        currentUserId,
        unlikedGarment.id,
      );

      // A futuro: ¿Debería eliminarse una notificación de "like" si se deshace el like?

      print("MatchProvider: Unlike garment ${unlikedGarment.id}");
      return true;
    } catch (e) {
      _matchErrorMessage = "Error al quitar el like: ${e.toString()}";
      print("MatchProvider Error - handleUnlikeGarment: $e");
      return false;
    }
  }

  void consumeMatchFeedback() {
    if (_showMatchFeedback) {
      _showMatchFeedback = false;
      _lastCreatedMatch =
          null;
      notifyListeners();
    }
  }
}
