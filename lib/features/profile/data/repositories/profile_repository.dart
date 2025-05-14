import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../auth/data/models/user_model.dart'; // Necesitarás UserModel
import '../../../garment/data/models/garment_model.dart'; // Necesitarás GarmentModel
import 'package:chat_app/app/config/constants/firestore_collections.dart';

abstract class ProfileRepository {
  // --- Obtención de Datos del Perfil ---
  Future<UserModel?> getUserProfile(String userId);
  Future<List<GarmentModel>> getUserUploadedGarments(String userId, {DocumentSnapshot? lastVisible, int limit = 10});

  // --- Edición de Datos del Perfil ---
  Future<void> updateUserProfileData(String userId, Map<String, dynamic> dataToUpdate);
  Future<String?> uploadProfilePicture(String userId, File imageFile); 
  
  
  // --- Interacciones (Likes/Dislikes del Usuario  ---
  Future<void> addLikedItemToMyProfile({required String currentUserId, required String likedGarmentId});
  Future<void> addDislikedItemToMyProfile({required String currentUserId, required String dislikedGarmentId}); // Ya lo hace FeedRepository, ¿centralizar?

  // --- Obtención de Interacciones (Para cargar en FeedProvider) ---
  Future<Set<String>> getMyLikedItemIds(String currentUserId);
  Future<Set<String>> getMyDislikedItemIds(String currentUserId);

  // Podrías añadir métodos para obtener contadores de swaps/valoraciones si los guardas en el perfil
  // Future<int> getStats(String userId);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  
  ProfileRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _firestore.collection(usersCollection).doc(userId).get();
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
  Future<List<GarmentModel>> getUserUploadedGarments(String userId, {DocumentSnapshot? lastVisible, int limit = 10}) async {
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
          .map((doc) => GarmentModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print("Error fetching user garments: $e");
      throw Exception("Failed to get user garments.");
    }
  }

  @override
  Future<void> updateUserProfileData(String userId, Map<String, dynamic> dataToUpdate) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update(dataToUpdate);
    } catch (e) {
      print("Error updating user profile: $e");
      throw Exception("Failed to update profile.");
    }
  }

  // --- Implementación de Interacciones ---
  @override
  Future<void> addLikedItemToMyProfile({required String currentUserId, required String likedGarmentId}) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(likedGarmentsCollection) // Nombre de la subcolección
          .doc(likedGarmentId)
          .set({'timestamp': FieldValue.serverTimestamp()}); // Guardar timestamp o solo el doc vacío
    } catch (e) {
      print("Error adding liked item to profile: $e");
      // Decide si lanzar excepción o solo loguear
    }
  }

  @override
  Future<void> addDislikedItemToMyProfile({required String currentUserId, required String dislikedGarmentId}) async {
   
    try {
      await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(dislikedGarmentsCollection) 
          .doc(dislikedGarmentId)
          .set({'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      print("Error adding disliked item to profile: $e");
    }
  }


  @override
  Future<Set<String>> getMyLikedItemIds(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(likedGarmentsCollection)
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print("Error fetching liked item IDs: $e");
      return {}; // Devuelve set vacío en caso de error
    }
  }

  @override
  Future<Set<String>> getMyDislikedItemIds(String currentUserId) async {
    try {
     
      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(dislikedGarmentsCollection) 
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print("Error fetching disliked item IDs: $e");
      return {};
    }
  }

   @override
   Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try{
      // 1. Crear una referencia en Firebase Storage mediante el userId y un timestamp
      final String fileName =  'profile_pictures/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(fileName);

      // 2. Subir el archivo
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      // 3. Esperar a que la subida se complete
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});

      // 4. Obtener la URL de descarga
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Actualizar photoUrl en el doc del usuario en Firestore
      await updateUserProfileData(userId, {'photoUrl' : downloadUrl});
      return downloadUrl;
    } catch (e){
      print("Error uploading profile picture: $e");
      if (e is FirebaseException) {
        print("Firebase Storage Error Code: ${e.code}");
        print("Firebase Storage Error Message: ${e.message}");
      }
      return null; // Indica que la subida falló
    }
  }
}