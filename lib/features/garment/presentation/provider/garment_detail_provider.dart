import 'package:flutter/foundation.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/match/presentation/provider/match_provider.dart';
import '../../data/models/garment_model.dart';
import '../../data/repositories/garment_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';

class GarmentDetailProvider extends ChangeNotifier {
  final GarmentRepository _garmentRepository;
  final ProfileRepository _profileRepository;
  final AuthProviderC _authProvider;
  final MatchProvider _matchProvider;

  GarmentDetailProvider({
    required GarmentRepository garmentRepository,
    required ProfileRepository profileRepository,
    required AuthProviderC authProvider,
    required MatchProvider matchProvider,
  }) : _garmentRepository = garmentRepository,
       _profileRepository = profileRepository,
       _authProvider = authProvider,
       _matchProvider = matchProvider;

  GarmentModel? _garment;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLikedByCurrentUser = false;

  GarmentModel? get garment => _garment;
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
      _errorMessage = _garment == null ? "Prenda no encontrada" : null;

      _isLikedByCurrentUser =
          _authProvider.currentUserId != _garment!.ownerId
              ? await _profileRepository.haveILikedThisGarment(
                _authProvider.currentUserId!,
                garmentId,
              )
              : false;
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

    if (_garment!.ownerId == _authProvider.currentUserId) {
      _errorMessage = "No puedes interactuar con tu propia prenda así.";
      notifyListeners();
      return false;
    }

    bool operationSuccessful =
        false; // Para rastrear el éxito de la operación del MatchProvider
    bool previousLikedState =
        _isLikedByCurrentUser; // Guardar estado anterior para posible reversión

    // 1. Actualizar la UI inmediatamente (optimistic update)
    _isLikedByCurrentUser = !_isLikedByCurrentUser;
    _errorMessage = null; // Limpiar errores previos
    notifyListeners(); // Notificar el cambio optimista en la UI

    try {
      if (_isLikedByCurrentUser) {
        // El nuevo estado de la UI es "liked"
        print("GarmentDetailProvider: Intentando dar LIKE a ${_garment!.id}");
        operationSuccessful = await _matchProvider.handleLikeGarment(
          likedGarment: _garment!,
        );
      } else {
        // El nuevo estado de la UI es "unliked"
        print(
          "GarmentDetailProvider: Intentando quitar LIKE a ${_garment!.id}",
        );
        operationSuccessful = await _matchProvider.handleUnlikeGarment(
          unlikedGarment: _garment!,
        );
      }

      if (!operationSuccessful) {
        // Si la operación del MatchProvider falló (pero no lanzó una excepción, solo devolvió false)
        // o si MatchProvider actualizó su propio mensaje de error.
        _errorMessage =
            _matchProvider.matchErrorMessage ??
            "La acción no se pudo completar.";
        print(
          "GarmentDetailProvider: Operación de MatchProvider falló. Error: $_errorMessage",
        );
      } else {
        _errorMessage =
            null; // Limpiar mensaje de error si la operación fue exitosa
        print("GarmentDetailProvider: Operación de MatchProvider exitosa.");
      }
    } catch (e) {
      // Si ocurre una excepción inesperada durante la llamada al MatchProvider
      _errorMessage = "Error inesperado al actualizar el like: ${e.toString()}";
      print(
        "GarmentDetailProvider: Excepción al interactuar con MatchProvider: $e",
      );
      operationSuccessful = false; // Marcar la operación como fallida
    } finally {
      // 2. Revertir la UI si la operación de backend falló
      if (!operationSuccessful) {
        _isLikedByCurrentUser = previousLikedState; // Volver al estado original
        // El _errorMessage ya debería estar seteado por el try/catch o la comprobación de !operationSuccessful
      }
      // Notificar cualquier cambio final (estado de like revertido o mensaje de error)
      notifyListeners();
    }

    return operationSuccessful; // Devolver el resultado final de la operación de backend
  }

  Future<bool> deleteThisGarment() async {
    try {
      if (_garment == null) return false;
      _isLoading = true;
      await _garmentRepository.deleteGarment(_garment!.id, _garment!.imageUrls);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Error al eliminar la prenda: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
