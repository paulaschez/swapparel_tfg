//import 'package:chat_app/features/auth/data/repositories/auth_repository.dart';
import 'package:chat_app/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart'; // Para ChangeNotifier
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/feed_repository.dart';
import '../../../garment/data/models/garment_model.dart';
import 'package:chat_app/app/config/constants/firestore_collections.dart'; // <--- IMPORTA AQUÍ

//import 'package:chat_app/features/auth/presentation/provider/auth_provider.dart';

// TODO: Importar un posible MatchRepository si el chequeo de match se hace aquí

class FeedProvider extends ChangeNotifier {
  final FeedRepository _feedRepository;
  final String _currentUserId; // Necesitas el ID del usuario actual
  final ProfileRepository _profileRepository;

  // TODO: Considerar inyectar MatchRepository si el match check se hace aquí
  // final MatchRepository _matchRepository;

  FeedProvider({
    required FeedRepository feedRepository,
    required String currentUserId,
    required ProfileRepository profileRepository,
    // required MatchRepository matchRepository,
  }) : _feedRepository = feedRepository,
       _currentUserId = currentUserId,
       _profileRepository = profileRepository;
  // _matchRepository = matchRepository;

  List<GarmentModel> _garments = []; // Lista de prendas a mostrar en el feed
  bool _isLoading = false;
  bool _hasMoreGarments = true; // Para saber si podemos cargar más
  String? _errorMessage;
  DocumentSnapshot? _lastVisibleDocument; // Para paginación

  // --- Listas de IDs de Interacción---
  Set<String> _likedGarmentIds = {};
  Set<String> _dislikedGarmentIds = {};

  // --- Getters ---
  List<GarmentModel> get garments => _garments;
  bool get isLoading => _isLoading;
  bool get hasMoreGarments =>
      _hasMoreGarments; // La UI puede usar esto para no mostrar "cargar más"
  String? get errorMessage => _errorMessage;
  bool get canSwipe => _garments.isNotEmpty && !_isLoading;
  String get currentUserId => _currentUserId;

  // --- Métodos Públicos ---

  Future<void> initializeFeed() async {
    // Llamado al inicio o cuando se refresca el feed
    _isLoading = true;
    _hasMoreGarments = true;
    _errorMessage = null;
    _garments = [];
    _lastVisibleDocument = null;
    notifyListeners();

    await _loadUserInteractions();
    await fetchMoreGarments(isInitialLoad: true);
  }

  // Método principal para cargar prendas
  Future<void> fetchMoreGarments({
    bool isInitialLoad = false,
    int minBatchSize = 5,
  }) async {
    if (_isLoading || !_hasMoreGarments) return;

    _isLoading = true;
    if (!isInitialLoad) {
      notifyListeners();
    } // No notificar al inicio para evitar doble build

    List<GarmentModel> newValidGarments = [];

    try {
      while (newValidGarments.length < minBatchSize && _hasMoreGarments) {
        final List<GarmentModel> fetchedBatch = await _feedRepository
            .getGarmentsForFeed(
              currentUserId: _currentUserId,
              lastVisibleDocument: _lastVisibleDocument,
              limit: 10, // Pide un lote más grande para tener margen al filtrar
            );

        if (fetchedBatch.isEmpty) {
          _hasMoreGarments = false;
          break; // Salir del bucle si Firestore no devuelve más
        }

        // Actualizar el último documento visible para la siguiente paginación
        if (fetchedBatch.isNotEmpty) {
          _lastVisibleDocument = await _getDocSnapshotForGarment(
            fetchedBatch.last.id,
          );
        }

        // Filtrar el lote
        for (var garment in fetchedBatch) {
          if (!_likedGarmentIds.contains(garment.id) &&
              !_dislikedGarmentIds.contains(garment.id)) {
            newValidGarments.add(garment);
            if (newValidGarments.length >= minBatchSize) {
              break; // Salir si ya tenemos suficientes
            }
          }
        }
        // Si después de un lote no tenemos suficientes y aún hay más, el bucle continuará
      }

      _garments.addAll(newValidGarments);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print("FeedProvider Error: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> swipeRight(GarmentModel garment) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Quitar la prenda de la lista actual
      _garments.removeWhere((g) => g.id == garment.id);

      // 2. Registrar el like en el repositorio
      await _feedRepository.likeGarment(
        likerUserId: _currentUserId,
        likedGarmentId: garment.id,
        likedGarmentOwnerId: garment.ownerId,
      );

      // 3. Añadir a la lista local de likes para no volver a mostrarla
      _likedGarmentIds.add(garment.id);

      // 4.  Persistir este cambio en _likedGarmentIds en Firestore para el usuario
      await _profileRepository.addLikedItemToMyProfile(
        currentUserId: _currentUserId,
        likedGarmentId: garment.id,
      );

      // 5. Comprobar si hay match (Aquí o llamando a un MatchProvider/Repository)
      // bool didMatch = await _matchRepository.checkForMatch(...);
      // if (didMatch) {
      //   // Mostrar notificación de match, crear chat, etc.
      // }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      // ¿Volver a añadir la prenda a la lista si el like falla? Considerar.
    } finally {
      _isLoading = false;
      notifyListeners();
      // Cargar más si quedan pocas prendas
      if (_garments.length < 3 && _hasMoreGarments) {
        // Umbral, ajústalo
        fetchMoreGarments();
      }
    }
  }

  Future<void> swipeLeft(GarmentModel garment) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Quitar la prenda de la lista actual
      _garments.removeWhere((g) => g.id == garment.id);

      // 2. Registrar el dislike en el repositorio del perfil
      await _profileRepository.addDislikedItemToMyProfile(
        currentUserId: _currentUserId,
        dislikedGarmentId: garment.id,
      );

      // 3. Añadir a la lista local de dislikes
      _dislikedGarmentIds.add(garment.id);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      // Cargar más si quedan pocas prendas
      if (_garments.length < 3 && _hasMoreGarments) {
        fetchMoreGarments();
      }
    }
  }

  // --- Métodos Helper Privados ---

  // Necesario para obtener el DocumentSnapshot para la paginación
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

  Future<void> _loadUserInteractions() async {
    try {
      // Cargar IDs de prendas likeadas por el usuario
      final likedSnapshot =
          await FirebaseFirestore.instance
              .collection(usersCollection)
              .doc(_currentUserId)
              .collection('likedItems')
              .get();
      _likedGarmentIds = likedSnapshot.docs.map((doc) => doc.id).toSet();

      // Cargar IDs de prendas dislikeadas por el usuario
      final dislikedSnapshot =
          await FirebaseFirestore.instance
              .collection(usersCollection)
              .doc(_currentUserId)
              .collection('dislikedItems')
              .get();
      _dislikedGarmentIds = dislikedSnapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print("Error loading user interactions: $e");
    }
  }
}
