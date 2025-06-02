// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../garment/data/models/garment_model.dart';
import 'package:swapparel/app/config/constants/firestore_collections.dart';

abstract class FeedRepository {
  // Obtiene un lote de prendas para el feed, excluyendo las del usuario actual.
  // Usa 'lastVisibleDocument' para paginación.
  Future<List<GarmentModel>> getGarmentsForFeed({
    required String currentUserId,
    DocumentSnapshot? lastVisibleDocument,
    int limit = 10, // Número de prendas a cargar por lote
  });

  // Registra que a un usuario le gustó una prenda en la lista global de likes.
  Future<void> likeGarment({
    required String likerUserId, // Quién da el like
    required String likedGarmentId, // Qué prenda recibe el like
    required String
    likedGarmentOwnerId, // Dueño de la prenda que recibe el like
  });

  Future<void> removeLikeFromGlobalCollection({
    required String likerUserId,
    required String likedGarmentId,
  });
}

class FeedRepositoryImpl implements FeedRepository {
  final FirebaseFirestore _firestore;

  FeedRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<List<GarmentModel>> getGarmentsForFeed({
    required String currentUserId,
    DocumentSnapshot? lastVisibleDocument,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection(garmentsCollection)
          .where(
            'ownerId',
            isNotEqualTo: currentUserId,
          ) // No mostrar las prendas propias del usuario
          .where('isAvailable', isEqualTo: true)
          .orderBy('ownerId')
          .orderBy(
            'createdAt',
            descending: true,
          ); // Ordenar por más recientes primero

      if (lastVisibleDocument != null) {
        query = query.startAfterDocument(lastVisibleDocument);
      }

      final querySnapshot = await query.limit(limit).get();

      final garments =
          querySnapshot.docs
              .map(
                (doc) => GarmentModel.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList();
      return garments;
    } catch (e) {
      print("Error fetching garments for feed: $e");
      throw Exception("Failed to load garments.");
    }
  }

  @override
  Future<void> likeGarment({
    required String likerUserId,
    required String likedGarmentId,
    required String likedGarmentOwnerId,
  }) async {
    try {
      final likeData = {
        'likerUserId': likerUserId,
        'likedGarmentId': likedGarmentId,
        'likedGarmentOwnerId': likedGarmentOwnerId,
        'timestamp': FieldValue.serverTimestamp(),
      };
      // Crear un ID único para el like autogenerado por firestore
      await _firestore.collection(likesCollection).add(likeData);

      print("Garment $likedGarmentId liked by $likerUserId");
    } catch (e) {
      print("Error liking garment: $e");
      throw Exception("Failed to like garment.");
    }
  }

  @override
  Future<void> removeLikeFromGlobalCollection({
    required String likerUserId,
    required String likedGarmentId,
  }) async {
    try {
      final QuerySnapshot querySnapshot =
          await _firestore
              .collection(likesCollection)
              .where('likerUserId', isEqualTo: likerUserId)
              .where('likedGarmentId', isEqualTo: likedGarmentId)
              .get();

      // Verificar si se encontró un documento
      if (querySnapshot.docs.isNotEmpty) {
        final String docIdToDelete = querySnapshot.docs.first.id;
        await _firestore
            .collection(likesCollection)
            .doc(docIdToDelete)
            .delete();
        print(
          "FeedRepo: Like eliminado de la colección global 'likes'. Doc ID: $docIdToDelete",
        );
      } else {
        // No se encontró un like que coincida.
        print(
          "FeedRepo Warning: No se encontró un 'like' para eliminar con likerUserId: $likerUserId, likedGarmentId: $likedGarmentId",
        );
      }
    } catch (e) {
      print("FeedRepo Error - removeLikeFromGlobalCollection: $e");
      throw Exception("Failed to remove like from global collection.");
    }
  }
}
