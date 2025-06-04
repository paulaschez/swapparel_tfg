// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swapparel/app/config/constants/firestore_user_fields.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../garment/data/models/garment_model.dart';
import 'package:swapparel/app/config/constants/firestore_collections.dart';

abstract class ProfileRepository {
  Future<UserModel?> getUserProfile(String userId);
  Future<List<GarmentModel>> getUserUploadedGarments(
    String userId, {
    DocumentSnapshot? lastVisible,
    int limit = 10,
    bool isAvailable = true,
  });
  Future<bool> checkIfUsernameExists(String username, {String? currentUserId});
  Future<void> updateUserProfileData(
    String userId,
    Map<String, dynamic> dataToUpdate, {
    String? photoUrlToDelete,
  });
  Future<String?> uploadProfilePicture(String userId, XFile imageXFile);

  // --- Interacciones (Likes/Dislikes del Usuario  ---
  Future<void> addLikedGarmentToMyProfile({
    required String currentUserId,
    required String likedGarmentId,
  });
  Future<void> addDislikedGarmentToMyProfile({
    required String currentUserId,
    required String dislikedGarmentId,
  });

  Future<bool> haveILikedThisGarment(String currentUserId, String garmenId);
  Future<void> removeLikedGarmentFromMyProfile(
    String currentUserId,
    String likedGarmentId,
  );

  // --- Obtención de Interacciones (Para cargar en FeedProvider) ---
  Future<Set<String>> getMyLikedGarmentIds(String currentUserId);
  Future<Set<String>> getMyDislikedGarmentIds(String currentUserId);

  Future<void> incrementSwapCount(
    String userId, {
    required Transaction transaction,
  });

  Future<void> updateUserRatingProfile({
    required String userId,
    required double newRatingStars,
    required Transaction transaction, // Aceptar una transacción opcional
  });
}

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  ProfileRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage,
       _uuid = const Uuid();

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection(usersCollection).doc(userId).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print("Error fetching user profile: $e");
      throw Exception("Failed to get user profile.");
    }
  }

  @override
  Future<List<GarmentModel>> getUserUploadedGarments(
    String userId, {
    DocumentSnapshot? lastVisible,
    int limit = 10,
    bool isAvailable = true,
  }) async {
    try {
      Query query = _firestore
          .collection(garmentsCollection)
          .where('ownerId', isEqualTo: userId)
          .where('isAvailable', isEqualTo: isAvailable)
          .orderBy('createdAt', descending: true);

      if (lastVisible != null) {
        query = query.startAfterDocument(lastVisible);
      }

      final querySnapshot = await query.limit(limit).get();
      return querySnapshot.docs
          .map(
            (doc) => GarmentModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    } catch (e) {
      print("Error fetching user garments: $e");
      throw Exception("Failed to get user garments.");
    }
  }

  @override
  Future<void> updateUserProfileData(
    String userId,
    Map<String, dynamic> dataToUpdate, {
    String? photoUrlToDelete,
  }) async {
    try {
      // 1. Eliminar la foto antigua de Storage si se proporcionó la URL
      if (photoUrlToDelete != null && photoUrlToDelete.isNotEmpty) {
        try {
          Reference imageRef = _storage.refFromURL(photoUrlToDelete);
          print(
            "ProfileRepo: Eliminando imagen de Storage: $photoUrlToDelete (Ruta: ${imageRef.fullPath})",
          );
          await imageRef.delete(); 
          print("ProfileRepo: Imagen eliminada de Storage: $photoUrlToDelete");
        } catch (e) {
          print(
            "ProfileRepo Warning - deleteOldPhoto: No se pudo eliminar $photoUrlToDelete. Error: $e",
          );
        }
      }

      // 2. Actualizar los datos en Firestore (solo si hay algo que actualizar)
      if (dataToUpdate.isNotEmpty) {
        await _firestore
            .collection(usersCollection)
            .doc(userId)
            .update(dataToUpdate);
        print(
          "ProfileRepo: Datos de perfil actualizados en Firestore para $userId.",
        );
      } else if (photoUrlToDelete != null) {
        print(
          "ProfileRepo: Solo se eliminó la foto, no hubo otros datos para actualizar en Firestore para $userId.",
        );
      }
    } catch (e) {
      print("Error updating user profile: $e");
      throw Exception("Failed to update profile.");
    }
  }

  @override
  Future<void> addLikedGarmentToMyProfile({
    required String currentUserId,
    required String likedGarmentId,
  }) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(likedGarmentsCollection) // Nombre de la subcolección
          .doc(likedGarmentId)
          .set({'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      print("Error adding liked Garment to profile: $e");
    }
  }

  @override
  Future<void> addDislikedGarmentToMyProfile({
    required String currentUserId,
    required String dislikedGarmentId,
  }) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(dislikedGarmentsCollection)
          .doc(dislikedGarmentId)
          .set({'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      print("Error adding disliked Garment to profile: $e");
    }
  }

  @override
  Future<Set<String>> getMyLikedGarmentIds(String currentUserId) async {
    try {
      final snapshot =
          await _firestore
              .collection(usersCollection)
              .doc(currentUserId)
              .collection(likedGarmentsCollection)
              .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print("Error fetching liked Garment IDs: $e");
      return {}; // Devuelve set vacío en caso de error
    }
  }

  @override
  Future<Set<String>> getMyDislikedGarmentIds(String currentUserId) async {
    try {
      final snapshot =
          await _firestore
              .collection(usersCollection)
              .doc(currentUserId)
              .collection(dislikedGarmentsCollection)
              .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print("Error fetching disliked Garment IDs: $e");
      return {};
    }
  }

  @override
  Future<bool> haveILikedThisGarment(
    String currentUserId,
    String garmentId,
  ) async {
    try {
      final likedDocSnapshot =
          await _firestore
              .collection(usersCollection)
              .doc(currentUserId)
              .collection(likedGarmentsCollection)
              .doc(garmentId)
              .get();
      // Si el documento existe, significa que el usuario le ha dado like a esta prenda.
      print(
        "ProfileRepo: haveILikedThisGarment - User: $currentUserId, Garment: $garmentId, Exists: ${likedDocSnapshot.exists}",
      );
      return likedDocSnapshot.exists;
    } catch (e) {
      print(
        "ProfileRepo Error - haveILikedThisGarment for User: $currentUserId, Garment: $garmentId. Error: $e",
      );
      // En caso de error, es más seguro asumir que no le ha dado like
      return false;
    }
  }

  @override
  Future<void> removeLikedGarmentFromMyProfile(
    String currentUserId,
    String likedGarmentId,
  ) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(likedGarmentsCollection)
          .doc(likedGarmentId)
          .delete();

      print(
        "ProfileRepo: removeLikedGarmentFromMyProfile - User: $currentUserId has disliked Garment: $likedGarmentId",
      );
    } catch (e) {
      print(
        "ProfileRepo Error - removeLikedGarmentFromMyProfile for  User: $currentUserId and  Garment: $likedGarmentId. Error $e",
      );
    }
  }

  @override
  Future<String?> uploadProfilePicture(String userId, XFile imageXFile) async {
    try {
      // 1. Crear una referencia en Firebase Storage mediante el userId y un timestamp
      final String fileName =
          'profile_pictures/$userId/profile_${_uuid.v4()}${imageXFile.mimeType?.replaceAll("image/", ".") ?? ".jpg"}';
      final Reference storageRef = _storage.ref().child(fileName);

      // 2. Subir el archivo
      final UploadTask uploadTask;
      if (kIsWeb) {
        final Uint8List bytes = await imageXFile.readAsBytes();
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: imageXFile.mimeType ?? 'image/jpeg'),
        );
      } else {
        uploadTask = storageRef.putFile(
          File(imageXFile.path),
          SettableMetadata(contentType: imageXFile.mimeType ?? 'image/jpeg'),
        );
      }

      // 3. Esperar a que la subida se complete
      final TaskSnapshot snapshot = await uploadTask;

      // 4. Obtener la URL de descarga
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print("Error uploading profile picture: $e");
      if (e is FirebaseException) {
        print("Firebase Storage Error Code: ${e.code}");
        print("Firebase Storage Error Message: ${e.message}");
      }
      return null; // Indica que la subida falló
    }
  }

  @override
  Future<bool> checkIfUsernameExists(
    String username, {
    String? currentUserId,
  }) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(usersCollection)
              .where(usernameField, isEqualTo: username.trim())
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // Username no existe
      }

      if (currentUserId != null &&
          querySnapshot.docs.first.id == currentUserId) {
        return false; // Es el propio username del usuario
      }
      return true; // Username existe y pertenece a otro usuario
    } catch (e) {
      print("ProfileRepo Error - checkIfUsernameExists: $e");
      return true; // Por seguridad, si hay error, asumir que podría existir
    }
  }

  @override
  Future<void> incrementSwapCount(
    String userId, {
    required Transaction transaction,
  }) async {
    if (userId.isEmpty) {
      print("ProfileRepo Warning: userId está vacío en incrementSwapCount.");
      return;
    }

    final DocumentReference userDocRef = _firestore
        .collection(usersCollection)
        .doc(userId);

    final Map<String, dynamic> dataToUpdate = {
      swapCountField: FieldValue.increment(1),
    };

    try {
      transaction.update(userDocRef, dataToUpdate);
      print("ProfileRepo (TX): Swap count incrementado para usuario $userId");
    } catch (e) {
      print(
        "ProfileRepo Error - incrementSwapCount for user $userId (TX: $transaction: $e",
      );
      throw Exception("Failed to increment swap count for user $userId.");
    }
  }

  @override
  Future<void> updateUserRatingProfile({
    required String userId,
    required double newRatingStars,
    required Transaction transaction,
  }) async {
    if (userId.isEmpty) {
      print(
        "ProfileRepo Warning: userId está vacío en updateUserRatingProfile.",
      );
      return;
    }
    if (newRatingStars < 1 || newRatingStars > 5) {
      print(
        "ProfileRepo Warning: newRatingStars ($newRatingStars) fuera de rango en updateUserRatingProfile.",
      );
      return;
    }

    final userDocRef = _firestore.collection(usersCollection).doc(userId);

    try {
      // 1. Leer el documento del usuario DENTRO de la transacción
      final DocumentSnapshot userSnapshot = await transaction.get(userDocRef);

      if (!userSnapshot.exists) {
        print(
          "ProfileRepo Error: User $userId not found during transaction in updateUserRatingProfile.",
        );
        // throw Exception("User $userId not found during rating update.");
        return; // O no hacer nada
      }

      final userData =
          userSnapshot.data() as Map<String, dynamic>?; // Tipado seguro

      // Obtener los valores actuales, con defaults si no existen
      final double currentTotalStars =
          (userData?[totalRatingStarsField] as num?)?.toDouble() ?? 0.0;
      final int currentNumberOfRatings =
          (userData?[numberOfRatingsField] as int?) ?? 0;

      // Calcular nuevos valores
      final double newTotalStars = currentTotalStars + newRatingStars;
      final int newNumberOfRatings = currentNumberOfRatings + 1;

      // 2. Actualizar el documento del usuario DENTRO de la transacción
      transaction.update(userDocRef, {
        totalRatingStarsField: newTotalStars,
        numberOfRatingsField: newNumberOfRatings,
      });
      print(
        "ProfileRepo: Rating profile updated for user $userId via transaction. New total stars: $newTotalStars, new count: $newNumberOfRatings",
      );
    } catch (e) {
      print("ProfileRepo Error - updateUserRatingProfile for user $userId: $e");
      throw Exception("Failed to update rating profile for user $userId.");
    }
  }
}
