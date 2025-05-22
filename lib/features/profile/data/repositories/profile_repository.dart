// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swapparel/app/config/constants/firestore_user_fields.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/data/models/user_model.dart'; // Necesitarás UserModel
import '../../../garment/data/models/garment_model.dart'; // Necesitarás GarmentModel
import 'package:swapparel/app/config/constants/firestore_collections.dart';

abstract class ProfileRepository {
  Future<UserModel?> getUserProfile(String userId);
  Future<List<GarmentModel>> getUserUploadedGarments(
    String userId, {
    DocumentSnapshot? lastVisible,
    int limit = 10,
  });
  Future<bool> checkIfUsernameExists(String username, {String? currentUserId});
  Future<void> updateUserProfileData(
    String userId,
    Map<String, dynamic> dataToUpdate,
  );
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

  // Future<int> getStats(String userId);
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
  }) async {
    try {
      Query query = _firestore
          .collection(garmentsCollection)
          .where('ownerId', isEqualTo: userId)
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
    Map<String, dynamic> dataToUpdate,
  ) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .update(dataToUpdate);
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

      // Actualizar photoUrl en el doc del usuario en Firestore
      //await updateUserProfileData(userId, {'photoUrl': downloadUrl});
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
}
