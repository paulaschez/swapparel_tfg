import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swapparel/features/auth/data/models/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/garment_repository.dart';
import '../../data/models/garment_model.dart';
import '../../../auth/presentation/provider/auth_provider.dart';

class GarmentProvider extends ChangeNotifier {
  final GarmentRepository _garmentRepository;
  final AuthProviderC _authProvider;
  final Uuid _uuid;

  GarmentProvider({
    required GarmentRepository garmentRepository,
    required AuthProviderC authProvider,
  }) : _authProvider = authProvider,
       _garmentRepository = garmentRepository,
       _uuid = const Uuid();

  bool _isUploading = false;
  String? _uploadErrorMessage;

  // Getters
  bool get isUploading => _isUploading;
  String? get uploadErrorMessage => _uploadErrorMessage;
  AuthProviderC get authProvider => _authProvider;

  Future<bool> submitNewGarment({
    required String name,
    String? description,
    required String category,
    String? size,
    required String condition,
    String? brand,
    String? color,
    String? material,
    required List<XFile> images,
  }) async {
    if (_authProvider.currentUserModel == null) {
      _setUploadError(
        "No se pudieron obtener los datos del perfil del usuario",
      );
      return false;
    }

    final UserModel owner = _authProvider.currentUserModel!;
    final String ownerUsername = owner.username;
    final String? ownerPhotoUrl = owner.photoUrl;
    _setUploading(true);
    _uploadErrorMessage = null;

    try {
      // Generar ID unico
      final String newGarmentId = _uuid.v4();

      // Subir imagenes a firebase storage y obtener url
      final List<String> imageUrls = await _garmentRepository
          .uploadGarmentImages(
            userId: _authProvider.currentUserId!,
            garmentId: newGarmentId,
            imageFiles: images,
          );

      // En caso de que falle y no se lance excepcion
      if (imageUrls.isEmpty && images.isNotEmpty) {
        throw Exception("Las imágenes no pudieron ser subidas");
      }

      final GarmentModel newGarment = GarmentModel(
        id: newGarmentId,
        ownerPhotoUrl: ownerPhotoUrl,
        ownerId: _authProvider.currentUserId!,
        ownerUsername: ownerUsername,
        name: name,
        imageUrls: imageUrls,
        createdAt: Timestamp.now(),
        isAvailable: true,
        color: color,
        category: category,
        condition: condition,
        size: size,
        description: description,
        brand: brand,
        material: material
      );

      // Guardar datos en firestore
      await _garmentRepository.addGarmentData(newGarment);

      _setUploading(false);
      return true;
    } catch (e) {
      _setUploadError(e.toString());
      _setUploading(false);
      return false; // Fallo
    }
  }

  void _setUploadError(String? message) {
    _uploadErrorMessage = message;
    notifyListeners();
  }

  void _setUploading(bool value) {
    _isUploading = value;
    if (value) {
      _uploadErrorMessage = null;
    }
    notifyListeners();
  }
}
