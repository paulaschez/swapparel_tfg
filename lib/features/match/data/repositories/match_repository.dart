import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swapparel/features/auth/data/models/user_model.dart';
import 'package:swapparel/features/inbox/notification/data/models/notification_model.dart';
import 'package:swapparel/features/inbox/notification/data/repositories/notification_repository.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../models/match_model.dart'; // Tu MatchModel

abstract class MatchRepository {
  // Comprueba si un nuevo like resulta en un match mutuo
  Future<MatchModel?> checkForAndCreateMatch({
    required String likerUserId, // Quien acaba de dar el like
    required String
    likedGarmentOwnerId, // Dueño de la prenda que recibió el like
    required String likedGarmentId, // ID de la prenda que recibió el like
  });

  // Obtiene los matches/conversaciones de un usuario
  Stream<List<MatchModel>> getMyMatches(String userId);

  Stream<MatchModel?> getMatchStream(String matchId);

  Future<void> updateMatchFields(
    String matchId,
    Map<String, dynamic> dataToUpdate, {
    Transaction? transaction,
  });

  Future<MatchModel?> checkForMatchAndNotify({
    required String likerUserId,
    required String likedGarmentOwnerId,
    required String likedGarmentId,
    // Pasar los datos necesarios para las notificaciones
    required String likerUsername,
    String? likerPhotoUrl,
    required String likedGarmentOwnerUsername,
  });
}

class MatchRepositoryImpl implements MatchRepository {
  final FirebaseFirestore _firestore;
  final NotificationRepository _notificationRepository;

  MatchRepositoryImpl({
    required FirebaseFirestore firestore,
    required NotificationRepository notificationRepository,
  }) : _firestore = firestore,
       _notificationRepository = notificationRepository;

  @override
  Future<MatchModel?> checkForAndCreateMatch({
    required String likerUserId,
    required String likedGarmentOwnerId,
    required String likedGarmentId,
  }) async {
    print(
      "MatchRepo DEBUG: checkForAndCreateMatch START - Liker: $likerUserId, Owner: $likedGarmentOwnerId, Garment: $likedGarmentId",
    );
    try {
      // 1. Comprobar si YA EXISTE un match entre estos dos usuarios (para evitar duplicados)
      List<String> sortedParticipantIds = [likerUserId, likedGarmentOwnerId]
        ..sort();
      String potentialMatchDocId = sortedParticipantIds.join('_');
      print(
        "MatchRepo DEBUG: Attempting to GET existing match: /matches/$potentialMatchDocId",
      );

      DocumentSnapshot existingMatchSnapshot =
          await _firestore
              .collection(matchesCollection)
              .doc(potentialMatchDocId)
              .get();
      print(
        "MatchRepo DEBUG: GET existing match successful. Exists: ${existingMatchSnapshot.exists}",
      );

      if (existingMatchSnapshot.exists) {
        print(
          "MatchRepo DEBUG: Match already exists. Returning existing match.",
        );

        final matchFetched = MatchModel.fromFirestore(
          existingMatchSnapshot as DocumentSnapshot<Map<String, dynamic>>,
        );

        if (matchFetched.matchStatus == MatchStatus.completed) {
          updateMatchFields(existingMatchSnapshot.id, {
            'matchStatus': MatchStatus.active.toString(),
          });
        }
        return matchFetched;
      }

      // 2. Buscar si `likedGarmentOwnerId` ha dado like a ALGUNA prenda de `likerUserId`
      print(
        "MatchRepo DEBUG: Attempting to QUERY likes collection for mutual like.",
      );

      final likesQuery =
          await _firestore
              .collection(likesCollection)
              .where(
                'likerUserId',
                isEqualTo: likedGarmentOwnerId,
              ) // El otro usuario es el liker
              .where(
                'likedGarmentOwnerId',
                isEqualTo: likerUserId,
              ) // Y le gustó una prenda del usuario actual
              .limit(1)
              .get();
      print(
        "MatchRepo DEBUG: QUERY likes collection successful. Docs found: ${likesQuery.docs.length}",
      );

      if (likesQuery.docs.isNotEmpty) {
        print("MatchRepo: Mutual like found!");

        // --- OBTENER DETALLES DE LOS PARTICIPANTES ---
        Map<String, Map<String, String?>> participantDetailsData = {};

        // Obtener UserModel del likerUserId (Usuario A)
        DocumentSnapshot userADoc =
            await _firestore.collection(usersCollection).doc(likerUserId).get();
        if (userADoc.exists) {
          UserModel userA = UserModel.fromFirestore(
            userADoc as DocumentSnapshot<Map<String, dynamic>>,
          );
          participantDetailsData[likerUserId] = {
            'name': userA.name,
            'photoUrl': userA.photoUrl,
          };
        } else {
          // Fallback si no se encuentra el perfil
          participantDetailsData[likerUserId] = {
            'name': 'Usuario $likerUserId',
            'photoUrl': null,
          };
        }
        // Obtener UserModel del likedGarmentOwnerId (Usuario B)
        DocumentSnapshot userBDoc =
            await _firestore
                .collection(usersCollection)
                .doc(likedGarmentOwnerId)
                .get();
        if (userBDoc.exists) {
          UserModel userB = UserModel.fromFirestore(
            userBDoc as DocumentSnapshot<Map<String, dynamic>>,
          );
          participantDetailsData[likedGarmentOwnerId] = {
            'name': userB.name, // O userB.displayName
            'photoUrl': userB.photoUrl,
          };
        } else {
          // Fallback
          participantDetailsData[likedGarmentOwnerId] = {
            'name': 'Usuario $likedGarmentOwnerId',
            'photoUrl': null,
          };
        }
        final Timestamp now = Timestamp.now();

        // ¡MATCH MUTUO!
        print("MatchRepo DEBUG: Mutual like found!");
        final String garmentIdFromOtherUser = likesQuery.docs.first.getString(
          'likedGarmentId',
        ); // Prenda del otro que me gustó

        final newMatch = MatchModel(
          id: potentialMatchDocId,
          participantIds: sortedParticipantIds,
          matchedItems: {
            likerUserId: likedGarmentId,
            likedGarmentOwnerId: garmentIdFromOtherUser,
          },
          unreadCounts: {likerUserId: 0, likedGarmentOwnerId: 0},
          participantDetails: participantDetailsData,
          createdAt: now,
          lastActivityAt: now,
          lastMessageSnippet: "¡Han hecho match! Inicia la conversación.",
        );
        print(
          "MatchRepo DEBUG: Attempting to CREATE new match document: /matches/${newMatch.id}",
        );
        await _firestore
            .collection(matchesCollection)
            .doc(newMatch.id)
            .set(newMatch.toJson());

        print("MatchRepo: Match document created with ID: ${newMatch.id}");
        return newMatch;
      } else {
        print("MatchRepo DEBUG: No mutual like found. Returning null.");

        return null;
      }
    } catch (e) {
      print("MatchRepo CATCH Error - checkForAndCreateMatch: $e");
      throw Exception("Failed to check for or create match.");
    }
  }

  @override
  Stream<List<MatchModel>> getMyMatches(String userId) {
    print("MatchRepository: getMyMatches CALLED for userId: '$userId'");
    if (userId.isEmpty) {
      print(
        "MatchRepository: getMyMatches - userId is empty, returning empty stream.",
      );

      return Stream.value([]);
    }
    try {
      final query = _firestore
          .collection(matchesCollection)
          .where('participantIds', arrayContains: userId)
          .orderBy(
            'lastActivityAt',
            descending: true,
          ); // Ordenar por la última actividad

      print(
        "MatchRepository: getMyMatches - Querying for matches with participantId: '$userId'",
      );

      return query.snapshots().map((snapshot) {
        print(
          "MatchRepository: getMyMatches - Firestore Snapshot for userId '$userId' RECIBIÓ ${snapshot.docs.length} match documents.",
        );
        return snapshot.docs
            .map(
              (doc) => MatchModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
              ),
            )
            .toList();
      });
    } catch (e) {
      print("MatchRepo Error - getMyMatchesStream: $e");
      return Stream.error(Exception("Failed to get matches stream."));
    }
  }

  @override
  Stream<MatchModel?> getMatchStream(String matchId) {
    print("MatchRepository: getMatchStream CALLED for matchId: '$matchId'");
    if (matchId.isEmpty) {
      print(
        "MatchRepository: getMatchStream - matchId is empty, returning empty stream.",
      );

      return Stream.value(null);
    }
    try {
      // 1. Obtener el Stream de DocumentSnapshots
      Stream<DocumentSnapshot<Map<String, dynamic>>> documentStream =
          _firestore
              .collection(matchesCollection)
              .doc(matchId)
              .snapshots()
              .cast<DocumentSnapshot<Map<String, dynamic>>>();

      // 2. Mapear cada DocumentSnapshot a un MatchModel?
      return documentStream
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              print(
                "MatchRepository: getMatchStream - Snapshot received for '$matchId'. Exists: true, Data: ${snapshot.data()}",
              );
              try {
                return MatchModel.fromFirestore(snapshot);
              } catch (e) {
                print(
                  "MatchRepository: getMatchStream - Error parsing MatchModel for '$matchId': $e. Snapshot data: ${snapshot.data()}",
                );
                return null;
              }
            } else {
              print(
                "MatchRepository: getMatchStream - Snapshot received for '$matchId'. Document does not exist or data is null.",
              );
              return null;
            }
          })
          .handleError((error) {
            print(
              "MatchRepository: getMatchStream - ERROR in stream for '$matchId': $error",
            );
            throw Exception("Stream error for match $matchId: $error");
          });
    } catch (e) {
      print(
        "MatchRepository: getMatchStream - FATAL ERROR setting up stream for '$matchId': $e",
      );
      return Stream.error(
        Exception("Failed to set up stream for match $matchId: $e"),
      );
    }
  }

  @override
  Future<void> updateMatchFields(
    String matchId,
    Map<String, dynamic> dataToUpdate, {
    Transaction? transaction,
  }) async {
    if (matchId.isEmpty || dataToUpdate.isEmpty) {
      print(
        "MatchRepo: updateMatchFields - matchId or dataToUpdate is empty. Skipping.",
      );
      return;
    }

    final docRef = _firestore.collection(matchesCollection).doc(matchId);
    final Map<String, dynamic> finalData = Map.from(dataToUpdate);

    finalData['lastActivityAt'] = FieldValue.serverTimestamp();

    print(
      "MatchRepo: Updating match $matchId with fields: $finalData (Transaction: ${transaction != null})",
    );

    try {
      if (transaction != null) {
        // Si se pasa una transacción se hace
        transaction.update(docRef, finalData);
        print(
          "MatchRepo: Match $matchId fields updated successfully via transaction.",
        );
      } else {
        // Si no, se hace una actualización normal
        await docRef.update(finalData);
        print(
          "MatchRepo: Match $matchId fields updated successfully (direct update).",
        );
      }
    } catch (e) {
      print("MatchRepo Error - updateMatchFields for $matchId: $e");
      throw Exception("Failed to update match fields for $matchId.");
    }
  }

  @override
  Future<MatchModel?> checkForMatchAndNotify({
    required String likerUserId,
    required String likedGarmentOwnerId,
    required String likedGarmentId,
    required String likerUsername,
    String? likerPhotoUrl,
    required String likedGarmentOwnerUsername,
  }) async {
    final MatchModel? match = await checkForAndCreateMatch(
      //
      likerUserId: likerUserId,
      likedGarmentOwnerId: likedGarmentOwnerId,
      likedGarmentId: likedGarmentId,
    );

    if (match != null) {
      final Duration timeSinceCreation = DateTime.now().difference(
        match.createdAt.toDate(),
      );
      final bool isNewlyCreatedOrReactivated = timeSinceCreation.inSeconds < 5;

      if ((match.matchStatus == MatchStatus.active &&
              isNewlyCreatedOrReactivated) ||
          match.matchStatus == MatchStatus.completed) {
        print("MatchRepository: ¡ES UN MATCH Y SE NOTIFICARÁ! ID: ${match.id}");

        // Notificación para el usuario actual (likerUserId)
        final matchNotificationForLiker = NotificationModel(
          id: '', // Firestore generará el ID
          recipientId: likerUserId,
          type: NotificationType.match,
          relatedUserId: likedGarmentOwnerId,
          relatedUserName: likedGarmentOwnerUsername,
          createdAt: Timestamp.now(),
          entityId: match.id,
        );
        await _notificationRepository.createNotification(
          matchNotificationForLiker,
        );

        // Notificación para el dueño de la prenda (likedGarmentOwnerId)
        final matchNotificationForOwner = NotificationModel(
          id: '',
          recipientId: likedGarmentOwnerId,
          type: NotificationType.match,
          relatedUserId: likerUserId,
          relatedUserName: likerUsername,
          createdAt: Timestamp.now(),
          entityId: match.id,
        );
        await _notificationRepository.createNotification(
          matchNotificationForOwner,
        );
        return match; // Devolver el match si se notificó
      } else if (match.matchStatus == MatchStatus.completed) {
        print(
          "MatchRepository: Match encontrado pero ya estaba completado. ID: ${match.id}",
        );
      } else if (match.matchStatus == MatchStatus.active &&
          !isNewlyCreatedOrReactivated) {
        print(
          "MatchRepository: Match activo encontrado pero no es nuevo ni reactivado recientemente. ID: ${match.id}",
        );
      }
    }
    return null;
  }
}

extension DocumentSnapshotExtension on DocumentSnapshot {
  String getString(String key) {
    return (data() as Map<String, dynamic>)[key] as String? ?? '';
  }
}
