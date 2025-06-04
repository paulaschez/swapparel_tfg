import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swapparel/features/inbox/notification/data/models/notification_model.dart';
import 'package:swapparel/features/inbox/notification/data/repositories/notification_repository.dart';
import 'package:swapparel/features/profile/data/repositories/profile_repository.dart'; // Para actualizar el perfil
import 'package:swapparel/features/match/data/repositories/match_repository.dart'; // Para actualizar el match
import 'package:swapparel/features/rating/data/models/rating_model.dart';

const String ratingsCollection = 'ratings';

abstract class RatingRepository {
  Future<void> submitRating(RatingModel rating);
}

class RatingRepositoryImpl implements RatingRepository {
  final FirebaseFirestore _firestore;
  final ProfileRepository _profileRepository;
  final MatchRepository _matchRepository;
  final NotificationRepository _notificationRepository;

  RatingRepositoryImpl({
    required FirebaseFirestore firestore,
    required ProfileRepository profileRepository,
    required MatchRepository matchRepository,
    required NotificationRepository notificationRepository,
  }) : _firestore = firestore,
       _profileRepository = profileRepository,
       _matchRepository = matchRepository,
       _notificationRepository = notificationRepository;

  @override
  Future<void> submitRating(RatingModel rating) async {
    try {
      // Transacción para asegurar la atomicidad de todas las escrituras
      await _firestore.runTransaction((transaction) async {
        // 1. Actualizar el UserModel del usuario valorado (ratedUserId)
        //    - Incrementar contador de valoraciones
        //    - Incrementar el numero de estrellas
        await _profileRepository.updateUserRatingProfile(
          userId: rating.ratedUserId,
          newRatingStars: rating.stars,
          transaction: transaction,
        );

        // 2. Guardar la nueva valoración
        DocumentReference ratingDocRef =
            _firestore.collection(ratingsCollection).doc();

        transaction.set(ratingDocRef, rating.toJson());

        // 3. Actualizar el MatchModel para marcar que este usuario (ratingUserId) ha valorado
        await _matchRepository.updateMatchFields(rating.matchId, {
          'hasUserRated.${rating.ratingUserId}': true,
        }, transaction: transaction);
      });
      print(
        "RatingRepository: Rating submitted successfully and related documents updated.",
      );

      // Notificar al usuario valorado
      try {
        final ratingNotification = NotificationModel(
          id: '',
          recipientId: rating.ratedUserId,
          type: NotificationType.newRating,
          relatedUserId: rating.ratingUserId,
          relatedUserName: rating.ratingUserName,
          createdAt: Timestamp.now(),
          message:
              '${rating.ratingUserName ?? "Un usuario"} te ha valorado: "${rating.comment?.trim()}". (${rating.stars} estrella/s).',
        );

        await _notificationRepository.createNotification(ratingNotification);
        print(
          "RatingRepository: New rating notification created for ${rating.ratedUserId}",
        );
      } catch (e) {
        print("RatingRepository: Failed to create new rating notification: $e");
      }
    } catch (e) {
      print("RatingRepository Error - submitRating: $e");
      throw Exception("Failed to submit rating: $e");
    }
  }
}
