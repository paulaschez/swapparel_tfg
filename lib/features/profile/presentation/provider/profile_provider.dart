import 'dart:io'; // Para File
import 'package:chat_app/app/config/constants/firestore_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para DocumentSnapshot
import '../../data/repositories/profile_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../garment/data/models/garment_model.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  ProfileProvider({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository;

  // Estado del perfil que se esta viendo
  UserModel? _viewedUserProfile;
  List<GarmentModel> _viewedUserGarments = [];
  bool _isLoadingProfile = false;
  String? _profileErrorMessage;
  DocumentSnapshot? _lastGarmentDocument;
  bool _hasMoreGarments = true;
  String? _currentlyFetchingUserId;

  // Geters
  UserModel? get viewedUserProfile => _viewedUserProfile;
  List<GarmentModel> get viewedUserGarments => _viewedUserGarments;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileErrorMessage => _profileErrorMessage;
  bool get hasMoreGarments => _hasMoreGarments;

  // Metodos

  // Obtiene las prendas del usuario (de 6 en 6)
  Future<void> fetchUserProfileAndGarments(
    String userId, {
    bool isRefresh = false,
  }) async {
    if (_isLoadingProfile && !isRefresh && _currentlyFetchingUserId == userId) {
      return; // Para evitar cargas multiples
    }

    _isLoadingProfile = true;
    _currentlyFetchingUserId = userId;

    if (isRefresh || _viewedUserProfile?.id != userId) {
      _viewedUserProfile = null;
      _viewedUserGarments = [];
      _lastGarmentDocument = null;
      _hasMoreGarments = true;
    }

    _profileErrorMessage = null;

    if (isRefresh || _viewedUserProfile == null) {
      notifyListeners();
    }

    try {
      // Cargar el perfil del usuario
      if (isRefresh ||
          _viewedUserProfile == null ||
          _viewedUserProfile!.id != userId) {
        // Solo si es una carga iniciar o si el userId cambió
        _viewedUserProfile = await _profileRepository.getUserProfile(userId);
      }

      // Cargar prendas
      if (_viewedUserProfile != null && _hasMoreGarments) {
        final newGarments = await _profileRepository.getUserUploadedGarments(
          userId,
          lastVisible: isRefresh ? null : _lastGarmentDocument,
          limit: 6,
        );

        isRefresh
            ? _viewedUserGarments = newGarments
            : _viewedUserGarments.addAll(newGarments);

        if (newGarments.isNotEmpty) {
          _lastGarmentDocument = await _getDocSnapshotForGarment(
            newGarments.last.id,
          );
        }

        if (newGarments.length < 6) {
          // Si devuelve menos del limite no hay mas
          _hasMoreGarments = false;
        }
      }

      _profileErrorMessage = null;
    } catch (e) {
      _profileErrorMessage = e.toString();
      print(
        "ProfileProvider Error - fetchUserProfileAndGarments: $_profileErrorMessage",
      );
    } finally {
      _isLoadingProfile = false;
      _currentlyFetchingUserId = null;

      notifyListeners();
    }
  }

  // Para recargar solo las prendas
  Future<void> refreshUserGarments(String userId) async {
    _lastGarmentDocument = null;
    _hasMoreGarments = true;
    _viewedUserGarments = [];
    await fetchUserProfileAndGarments(userId, isRefresh: true);
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? username,
    String? location,
    File? newProfileImage,
  }) async {
    _isLoadingProfile = true;
    _profileErrorMessage = null;
    notifyListeners();
    try {
      Map<String, dynamic> dataToUpdate = {};
      if (name != null) dataToUpdate['name'] = name;
      if (location != null) dataToUpdate['location'] = location;
      if (username != null) dataToUpdate['username'] = username;

      String? newPhotoUrl;
      if (newProfileImage != null) {
        newPhotoUrl = await _profileRepository.uploadProfilePicture(
          userId,
          newProfileImage,
        );
        newPhotoUrl != null
            ? dataToUpdate['photoUrl'] = newPhotoUrl
            : throw Exception("Fallo al subir la nueva foto de perfil");
      }
      if (dataToUpdate.isNotEmpty) {
        await _profileRepository.updateUserProfileData(userId, dataToUpdate);
      }

      // Recargar el perfil para reflejar los cambios
      await fetchUserProfileAndGarments(userId, isRefresh: false);
      _profileErrorMessage = null;
    } catch (e) {
      _profileErrorMessage = e.toString();
      print("ProfileProvider Error - updateUserProfile: $_profileErrorMessage");
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // Obtiene el  DocumentSnapshot para la paginacion
  Future<DocumentSnapshot?> _getDocSnapshotForGarment(String garmentId) async {
    try {
      return await FirebaseFirestore.instance
          .collection(garmentsCollection)
          .doc(garmentId)
          .get();
    } catch (e) {
      return null;
    }
  }

  // Limpia el estado cuando se sale de la pantalla de perfil
  void clearProfileData() {
    _viewedUserProfile = null;
    _viewedUserGarments = [];
    _isLoadingProfile = false;
    _profileErrorMessage = null;
    _lastGarmentDocument = null;
    _hasMoreGarments = true;
    _currentlyFetchingUserId = null;
  }
}
