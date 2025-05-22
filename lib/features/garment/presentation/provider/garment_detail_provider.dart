import 'package:flutter/foundation.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/feed/data/repositories/feed_repository.dart';
import '../../data/models/garment_model.dart';
import '../../data/repositories/garment_repository.dart';
//import '../../../auth/data/models/user_model.dart';
import '../../../profile/data/repositories/profile_repository.dart';

class GarmentDetailProvider extends ChangeNotifier {
  final GarmentRepository _garmentRepository;
  final ProfileRepository _profileRepository;
  final AuthProviderC _authProvider;
  final FeedRepository _feedRepository;

  GarmentDetailProvider({
    required GarmentRepository garmentRepository,
    required ProfileRepository profileRepository,
    required AuthProviderC authProvider,
    required FeedRepository feedRepository,
  }) : _garmentRepository = garmentRepository,
       _profileRepository = profileRepository,
       _authProvider = authProvider,
       _feedRepository = feedRepository;

  GarmentModel? _garment;
  //UserModel? _ownerProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLikedByCurrentUser = false;

  GarmentModel? get garment => _garment;
  //UserModel? get ownerProfile => _ownerProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLikedByCurrentUser => _isLikedByCurrentUser;

  Future<void> fetchGarmentDetails(String garmentId) async {
    if (garmentId.isEmpty) {
      _errorMessage = "ID de prenda inválido.";
      notifyListeners();
      return;
    }

    if (_isLoading && _garment?.id == garmentId) return;
    _isLoading = true;
    _errorMessage = null;

    if (_garment?.id != garmentId) {
      _garment = null;
      //_ownerProfile = null;
    }
    notifyListeners();

    try {
      _garment = await _garmentRepository.getGarmentById(garmentId);
      /* if (_garment != null) {
        // Obtenemos el perfil del dueño (si no es mi propia prenda) para evitar búsquedas innecesarias
        _ownerProfile =
            _garment!.id == _authProvider.currentUserId
                ? null
                : await _profileRepository.getUserProfile(_garment!.ownerId);
      } else {
        _errorMessage = "Prenda no encontrada";
      } */

      _errorMessage = _garment == null ? "Prenda no encontrada" : null;
      _isLikedByCurrentUser = await _profileRepository.haveILikedThisGarment(
        _authProvider.currentUserId!,
        garmentId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      print(
        "GarmentDetailProvider Error - fetchGarmentDetails: $_errorMessage",
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleLikeOnGarment() async {
    if (_garment == null || _authProvider.currentUserId == null) {
      _errorMessage = "Datos incompletos para la acción.";
      notifyListeners();
      return false;
    }

    // En caso de que se muestre el botón en la propia prenda (poco probable)
    if (_garment!.ownerId == _authProvider.currentUserId) {
      _errorMessage = "No puedes interactuar con tu propia prenda así.";
      notifyListeners();
      return false;
    }

    // TODO: Considerar un estado de carga específico para esta acción,
    //       para que el botón muestre un loader diferente al de carga de página.
    // _isLoadingLikeAction = true; notifyListeners();

    final String currentUserId = _authProvider.currentUserId!;
    final String garmentId = _garment!.id;
    final String ownerId = _garment!.ownerId;

    try {
      if (_isLikedByCurrentUser) {
        // Quitar like

        // Quitar de la coleccion global de likes
        _feedRepository.removeLikeFromGlobalCollection(likerUserId: currentUserId, likedGarmentId: garmentId);

        // Quitar de la coleccion de likes del usuario
        await _profileRepository.removeLikedGarmentFromMyProfile(
          currentUserId,
          garmentId,
        );
        _isLikedByCurrentUser = false;

        print("GarmentDetailProvider: Unlike garment $garmentId");
      } else {
        // Dar like

        // Registrar el like en la coleccion global
        await _feedRepository.likeGarment(
          likerUserId:currentUserId,
          likedGarmentId: garmentId,
          likedGarmentOwnerId: ownerId,
        );

        // Añadir a la lista de "myLikedItems" del usuario actual
        await _profileRepository.addLikedGarmentToMyProfile(
          currentUserId: currentUserId,
          likedGarmentId: garmentId,
        );
        _isLikedByCurrentUser = true;
              print("GarmentDetailProvider: Like garment $garmentId");


        //TODO: Comprobar si hubo match
      }
      _errorMessage = null;
      //_isLoadingLikeAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Error al actualizar el like: ${e.toString()}";
      //_isLoadingLikeAction = false;
      notifyListeners();
      return false;
    }
  }
}
