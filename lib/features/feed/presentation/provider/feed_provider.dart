import 'package:swapparel/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart'; // Para ChangeNotifier
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/feed_repository.dart';
import '../../../garment/data/models/garment_model.dart';
import 'package:swapparel/app/config/constants/firestore_collections.dart';

//import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';

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

    print("FeedProvider: Initializing feed for $_currentUserId");
    await _loadUserInteractions();
    print(
      "FeedProvider: User interactions loaded. Liked: ${_likedGarmentIds.length}, Disliked: ${_dislikedGarmentIds.length}",
    );
    if (_currentUserId.isNotEmpty) {
      await fetchMoreGarments(isInitialLoad: true);
    } else {
      _isLoading = false;
      _hasMoreGarments = false; // No hay más que cargar si no hay usuario
      _errorMessage = "Usuario no identificado para cargar el feed.";
      notifyListeners(); // Notificar este estado final
      print("FeedProvider: Cannot initialize feed, currentUserId is empty.");
    }
  }

  // Método principal para cargar prendas
  Future<void> fetchMoreGarments({
    bool isInitialLoad = false,
    int minBatchSize = 5,
  }) async {
    print(
      "FeedProvider: fetchMoreGarments called. isInitialLoad: $isInitialLoad, isLoading: $_isLoading, hasMore: $_hasMoreGarments",
    );
    if (_isLoading && !isInitialLoad) {
      print(
        "FeedProvider: fetchMoreGarments - Exiting: Already loading and not initial load.",
      );
      return;
    }

    if (!hasMoreGarments) {
      print(
        "FeedProvider: fetchMoreGarments - Exiting: No more garments to fetch.",
      );

      if (_isLoading) {
        // Solo si estaba en true por alguna razón (no debería si hasMore es false)
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    if (!isInitialLoad && !_isLoading) {
      // Si es una carga subsecuente Y no estábamos cargando antes
      _isLoading = true;
      notifyListeners();
    } else if (isInitialLoad && !_isLoading) {
      // Caso raro: es carga inicial pero initializeFeed no puso isLoading a true. Forzarlo.
      _isLoading = true;
    }
    List<GarmentModel> newValidGarments = [];
    print("FeedProvider: fetchMoreGarments - Entering try block.");

    try {
      while (newValidGarments.length < minBatchSize && _hasMoreGarments) {
        print(
          "FeedProvider: fetchMoreGarments - Inside while loop. newValid: ${newValidGarments.length}, minBatch: $minBatchSize, hasMore: $_hasMoreGarments",
        );
        final List<GarmentModel> fetchedBatch = await _feedRepository
            .getGarmentsForFeed(
              currentUserId: _currentUserId,
              lastVisibleDocument: _lastVisibleDocument,
              limit: 10, // Pide un lote más grande para tener margen al filtrar
            );

        print(
          "FeedProvider: fetchMoreGarments - Fetched batch size: ${fetchedBatch.length}",
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
      print(
        "FeedProvider: fetchMoreGarments finished. isLoading: $_isLoading, garments: ${_garments.length}",
      );
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
      await _profileRepository.addLikedGarmentToMyProfile(
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
      // ¿Volver a añadir la prenda a la lista si el like falla?
    } finally {
      _isLoading = false;
      notifyListeners();
      // Cargar más si quedan pocas prendas
      if (_garments.length < 3 && _hasMoreGarments) {
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
      await _profileRepository.addDislikedGarmentToMyProfile(
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
    if (_currentUserId.isEmpty) {
      // No intentar cargar si no hay ID
      _likedGarmentIds = {};
      _dislikedGarmentIds = {};
      print(
        "FeedProvider: Skipping _loadUserInteractions, currentUserId is empty.",
      );
      return;
    }
    print("FeedProvider: Loading user interactions for $_currentUserId");
    try {
      // Cargar IDs de prendas likeadas por el usuario
      final likedSnapshot =
          await FirebaseFirestore.instance
              .collection(usersCollection)
              .doc(_currentUserId)
              .collection('myLikedGarments')
              .get();
      _likedGarmentIds = likedSnapshot.docs.map((doc) => doc.id).toSet();

      // Cargar IDs de prendas dislikeadas por el usuario
      final dislikedSnapshot =
          await FirebaseFirestore.instance
              .collection(usersCollection)
              .doc(_currentUserId)
              .collection('myDislikedGarments')
              .get();
      _dislikedGarmentIds = dislikedSnapshot.docs.map((doc) => doc.id).toSet();

      print(
        "FeedProvider: Loaded liked: ${_likedGarmentIds.length}, disliked: ${_dislikedGarmentIds.length}",
      );
    } catch (e) {
      print("Error loading user interactions: $e");
      print("FeedProvider Error - _loadUserInteractions: $e");
      _likedGarmentIds = {}; // En caso de error, dejar las listas vacías
      _dislikedGarmentIds = {};
      _errorMessage = "Error al cargar interacciones del usuario.";
    }
  }
}
