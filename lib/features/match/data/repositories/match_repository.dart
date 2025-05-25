import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../app/config/constants/firestore_collections.dart';
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
  Future<List<MatchModel>> getMyMatches(String userId);
}

class MatchRepositoryImpl implements MatchRepository {
  final FirebaseFirestore _firestore;

  MatchRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

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
      //    El ID del match es user1Id_user2Id (ordenados alfabéticamente)
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
        return MatchModel.fromFirestore(
          existingMatchSnapshot as DocumentSnapshot<Map<String, dynamic>>,
        );
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
              .limit(1) // Solo necesitamos saber si existe al menos uno
              .get();
      print(
        "MatchRepo DEBUG: QUERY likes collection successful. Docs found: ${likesQuery.docs.length}",
      );

      if (likesQuery.docs.isNotEmpty) {
        // ¡MATCH MUTUO!
        print("MatchRepo DEBUG: Mutual like found!");
        final String garmentIdFromOtherUser = likesQuery.docs.first.getString(
          'likedGarmentId',
        ); // Prenda del otro que me gustó

        final newMatch = MatchModel(
          id: potentialMatchDocId, // Usar el ID predecible
          participantIds: sortedParticipantIds,
          matchedItems: {
            // Guardar qué prendas iniciaron este match específico
            likerUserId: likedGarmentId,
            likedGarmentOwnerId: garmentIdFromOtherUser,
          },
          createdAt: Timestamp.now(),
          lastActivityAt: Timestamp.now(),
        );
        print(
          "MatchRepo DEBUG: Attempting to CREATE new match document: /matches/${newMatch.id}",
        );
        await _firestore
            .collection(matchesCollection)
            .doc(newMatch.id)
            .set(newMatch.toJson());

        print("MatchRepo DEBUG: CREATE new match document successful.");
        return newMatch;
      } else {
        print("MatchRepo DEBUG: No mutual like found. Returning null.");

        return null; // No hay match (aún)
      }
      //TODO: Hacer transaccion??
    } catch (e) {
    print("MatchRepo CATCH Error - checkForAndCreateMatch: $e"); // Esto imprimirá el error de permiso
      throw Exception("Failed to check for or create match.");
    }
  }

  @override
  Future<List<MatchModel>> getMyMatches(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(matchesCollection)
              .where(
                'participantIds',
                arrayContains: userId,
              ) // El usuario es uno de los participantes
              .orderBy(
                'lastActivityAt',
                descending: true,
              ) // Mostrar los más recientes primero
              .get();

      return querySnapshot.docs
          .map(
            (doc) => MatchModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    } catch (e) {
      print("MatchRepo Error - getMyMatches: $e");
      throw Exception("Failed to get matches.");
    }
  }
}

// Necesitarás añadir getString a DocumentSnapshot (o hacer un cast seguro)
extension DocumentSnapshotExtension on DocumentSnapshot {
  String getString(String key) {
    return (data() as Map<String, dynamic>)[key] as String? ?? '';
  }
}
