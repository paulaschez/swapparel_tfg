import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swapparel/features/match/data/models/match_model.dart';
import '../../data/model/offer_model.dart';
import '../../data/repositories/offer_repository.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../../../match/data/repositories/match_repository.dart';
import '../../../inbox/notification/data/repositories/notification_repository.dart';
import '../../../inbox/notification/data/models/notification_model.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../garment/data/repositories/garment_repository.dart';

class OfferProvider extends ChangeNotifier {
  final OfferRepository _offerRepository;
  final AuthProviderC _authProvider;
  final MatchRepository _matchRepository; // Para actualizar el estado del match
  final GarmentRepository
  _garmentRepository; // Para actualizar disponibilidad de prendas
  final ProfileRepository _profileRepository; // Para contadores de swaps
  final NotificationRepository
  _notificationRepository; // Para enviar notificaciones

  OfferProvider({
    required OfferRepository offerRepository,
    required AuthProviderC authProvider,
    required MatchRepository matchRepository,
    required GarmentRepository garmentRepository,
    required ProfileRepository profileRepository,
    required NotificationRepository notificationRepository,
  }) : _offerRepository = offerRepository,
       _authProvider = authProvider,
       _matchRepository = matchRepository,
       _garmentRepository = garmentRepository,
       _profileRepository = profileRepository,
       _notificationRepository = notificationRepository;

  bool _isProcessingOffer = false;
  String? _offerError;

  bool get isProcessingOffer => _isProcessingOffer;
  String? get offerError => _offerError;
  AuthProviderC get authProvider => _authProvider;

  void _setProcessing(bool value) {
    _isProcessingOffer = value;
    if (value) _offerError = null;
    notifyListeners();
  }

  void _setError(String message) {
    _offerError = message;
    _isProcessingOffer = false;
    notifyListeners();
  }

  Future<bool> sendNewOffer({
    required String matchId,
    required String receivingUserId, // El ID del otro usuario en el match
    required List<OfferedItemInfo> myOfferedItems,
    required List<OfferedItemInfo> theirRequestedItems,
  }) async {
    if (_authProvider.currentUserId == null) {
      _setError("Usuario no autenticado.");
      return false;
    }
    if (myOfferedItems.isEmpty || theirRequestedItems.isEmpty) {
      _setError("Debes seleccionar prendas para ofrecer y solicitar.");
      return false;
    }

    _setProcessing(true);

    final newOffer = OfferModel(
      id: '', 
      matchId: matchId,
      offeringUserId: _authProvider.currentUserId!,
      receivingUserId: receivingUserId,
      offeredItems: myOfferedItems,
      requestedItems: theirRequestedItems,
      createdAt: Timestamp.now(),
      status: OfferStatus.pending,
    );

    try {
      await _offerRepository.createOffer(matchId, newOffer);

      // Enviar notificación al receivingUserId
      final String? currentUserName =
          _authProvider.currentUserModel?.displayName;
      final offerNotification = NotificationModel(
        id: '',
        recipientId: receivingUserId,
        type: NotificationType.newOffer,
        relatedUserId: _authProvider.currentUserId!,
        relatedUserName: currentUserName,
        entityId: matchId,
        createdAt: Timestamp.now(),
      );
      await _notificationRepository.createNotification(offerNotification);

      await _matchRepository.updateMatchFields(matchId, {
        'matchStatus': MatchStatus.offerMade.toString(),
        'lastMessageSnippet': "Oferta Pendiente",
        'unreadCounts.$receivingUserId': FieldValue.increment(1),
      });

      _setProcessing(false);
      return true;
    } catch (e) {
      _setError("Error al enviar la oferta: ${e.toString()}");
      return false;
    }
  }

  Future<bool> respondToOffer({
    required String matchId,
    required OfferModel offer, // La oferta completa que se está respondiendo
    required bool accepted, // true si acepta, false si rechaza
  }) async {
    if (_authProvider.currentUserId == null ||
        offer.receivingUserId != _authProvider.currentUserId) {
      _setError("No autorizado para responder a esta oferta.");
      return false;
    }
    if (offer.status != OfferStatus.pending) {
      _setError("Esta oferta ya no está pendiente.");
      return false;
    }

    _setProcessing(true);
    final newStatus = accepted ? OfferStatus.accepted : OfferStatus.declined;

    try {
      await _offerRepository.updateOfferStatus(matchId, offer.id, newStatus);

      final String? responderUsername =
          _authProvider.currentUserModel?.displayName;

      final offerAnswerNotification = NotificationModel(
        id: '',
        recipientId: offer.offeringUserId,
        type:
            newStatus == OfferStatus.accepted
                ? NotificationType.offerAccepted
                : NotificationType.offerDeclined,
        relatedUserId: offer.receivingUserId,
        relatedUserName: responderUsername,
        entityId: matchId,
        createdAt: Timestamp.now(),
      );
      await _notificationRepository.createNotification(offerAnswerNotification);
      if (accepted) {
        print("OfferProvider: Oferta aceptada. Completando el intercambio...");

        // 1. Marcar prendas como no disponibles
        List<String> allGarmentIdsInOffer = [
          ...offer.offeredItems.map((item) => item.garmentId),
          ...offer.requestedItems.map((item) => item.garmentId),
        ];

        print(
          "OfferProvider: Prendas a marcar como no disponibles: ${allGarmentIdsInOffer.join(', ')}",
        );

        for (String garmentId in allGarmentIdsInOffer) {
          print(
            "OfferProvider: Intentando actualizar la prenda con ID $garmentId",
          );
          await _garmentRepository.updateGarmentAvailability(garmentId, false);
        }

        // 2. Actualizar contadores de swaps de los usuarios
        await _profileRepository.incrementSwapCount(offer.offeringUserId);
        await _profileRepository.incrementSwapCount(offer.receivingUserId);

        // 3. Actualizar el estado del Match principal a 'completed' y notificar
        await _matchRepository.updateMatchFields(offer.matchId, {
          'matchStatus': MatchStatus.completed.toString(),
          'offerIdThatCompletedMatch': offer.id,
          'hasUserRated': {
            offer.offeringUserId: false,
            offer.receivingUserId: false,
          },
          'lastMessageSnippet': "¡Intercambio acordado!",
          'unreadCounts.${offer.offeringUserId}': FieldValue.increment(1),
        });
        print(
          "OfferProvider: Intercambio completado. Match status actualizado.",
        );
      } else {
        await _matchRepository.updateMatchFields(offer.matchId, {
          'matchStatus': MatchStatus.active.toString(),
          'lastMessageSnippet': "Oferta rechazada",
          'unreadCounts.${offer.offeringUserId}': FieldValue.increment(1),
        });
      }
      _setProcessing(false);
      return true;
    } catch (e) {
      _setError("Error al responder a la oferta: ${e.toString()}");
      return false;
    }
  }
}
