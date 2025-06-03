import 'package:flutter/widgets.dart';
import 'package:swapparel/features/auth/data/models/user_model.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/match/data/models/match_model.dart';
import 'package:swapparel/features/match/data/repositories/match_repository.dart';
import 'package:swapparel/features/inbox/notification/data/models/notification_model.dart';
import 'package:swapparel/features/inbox/notification/data/repositories/notification_repository.dart';
import 'package:swapparel/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/feed_repository.dart';
import '../../../garment/data/models/garment_model.dart';
import 'package:swapparel/app/config/constants/firestore_collections.dart';

class FeedProvider extends ChangeNotifier {
  final FeedRepository _feedRepository;
  final ProfileRepository _profileRepository;
  final MatchRepository _matchRepository;
  final NotificationRepository _notificationRepository;
  final AuthProviderC _authProvider;

  FeedProvider({
    required FeedRepository feedRepository,
    required ProfileRepository profileRepository,
    required MatchRepository matchRepository,
    required NotificationRepository notificationRepository,
    required AuthProviderC authProvider,
  }) : _feedRepository = feedRepository,
       _profileRepository = profileRepository,
       _matchRepository = matchRepository,
       _notificationRepository = notificationRepository,
       _authProvider = authProvider;

  List<GarmentModel> _garments = []; // Lista de prendas a mostrar en el feed
  bool _isLoading = false;
  bool _hasMoreGarments = true; // Para saber si podemos cargar más
  String? _errorMessage;
  DocumentSnapshot? _lastVisibleDocument; // Para paginación
  List<GarmentModel> _buffer = [];

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
  String? get currentUserId => _authProvider.currentUserId;
  UserModel? get _currentUserModel => _authProvider.currentUserModel;
  Set<String> get currentUserLikedGarmentIds => _likedGarmentIds;

  // --- Métodos Públicos ---

  Future<void> initializeFeed() async {
    // Llamado al inicio o cuando se refresca el feed
    _isLoading = true;
    _hasMoreGarments = true;
    _errorMessage = null;
    _garments = [];
    _buffer = [];
    _lastVisibleDocument = null;
    notifyListeners();

    print("FeedProvider: Initializing feed for $currentUserId");
    await _loadUserInteractions();
    print(
      "FeedProvider: User interactions loaded. Liked: ${_likedGarmentIds.length}, Disliked: ${_dislikedGarmentIds.length}",
    );
    if (currentUserId != null && currentUserId!.isNotEmpty) {
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

    if (currentUserId == null || currentUserId!.isEmpty) {
      _isLoading = false;
      _hasMoreGarments = false;
      notifyListeners();
      return;
    }

    if (_isLoading && !isInitialLoad) {
      print(
        "FeedProvider: fetchMoreGarments - Exiting: Already loading and not initial load.",
      );
      return;
    }

    // Vaciar la lista tanto para si es carga inicial o se están obteniendo más prendas (actualizar el cardsWiper)

    _garments = [];
    _isLoading = true;
    notifyListeners();

    if (!hasMoreGarments && !isInitialLoad && _buffer.isEmpty) {
      _isLoading = false; // Ya no estamos cargando
      notifyListeners();

      print(
        "FeedProvider: fetchMoreGarments - Exiting: No more garments to fetch.",
      );

      return;
    }

    List<GarmentModel> newGarmentsForFeed = [];
    print("FeedProvider: fetchMoreGarments - Entering try block.");

    try {
      while (newGarmentsForFeed.length < minBatchSize &&
          (_hasMoreGarments || _buffer.isNotEmpty)) {
        print(
          "FeedProvider: fetchMoreGarments - Inside while loop. newValid: ${newGarmentsForFeed.length}, minBatch: $minBatchSize, hasMore: $_hasMoreGarments, _buffer: ${_buffer.length}",
        );
        List<GarmentModel> candidatesToFilter = [];
        bool sourcedFromRepo =
            false; // Para saber si las prendas vienen del repo o del buffer

        // 1. Comprobar si el buffer tiene prendas guardadas
        if (_buffer.isNotEmpty) {
          print(
            "FeedProvider: Processing from buffer. Buffer size: ${_buffer.length}",
          );
          // Procesar prendas del buffer primero
          // Se copia  el buffer original para poder modificarlo
          List<GarmentModel> tempBufferProcessingList = List.from(_buffer);
          _buffer
              .clear(); // Se vacía el buffer, para ir rellenandose con lo que no se filtre

          for (GarmentModel garmentFromBuffer in tempBufferProcessingList) {
            if (newGarmentsForFeed.length >= minBatchSize) {
              _buffer.add(
                garmentFromBuffer,
              ); // Sobra para este lote, devolver al buffer
              continue;
            }

            // Filtrar por vistas (liked/disliked) (ya se ha hecho previamente, pero por si acaso )
            if (!_likedGarmentIds.contains(garmentFromBuffer.id) &&
                !_dislikedGarmentIds.contains(garmentFromBuffer.id)) {
              newGarmentsForFeed.add(
                garmentFromBuffer,
              ); // Prenda válida, añadir al lote
            } else {
              // Prenda ya vista, no se añade a newGarmentsForFeed ni se devuelve al buffer
              print(
                "FeedProvider: Garment ${garmentFromBuffer.id} from buffer already seen.",
              );
            }
          }
          print(
            "FeedProvider: After buffer processing. newGarmentsForFeed: ${newGarmentsForFeed.length}, new buffer size: ${_buffer.length}",
          );
        }

        // 3. Si el buffer está vacío (o no proveyó suficientes) Y AÚN hay más en el repo
        if (newGarmentsForFeed.length < minBatchSize && _hasMoreGarments) {
          print(
            "FeedProvider: Buffer insufficient or empty. Fetching from repository.",
          );
          final List<GarmentModel> fetchedBatch = await _feedRepository
              .getGarmentsForFeed(
                currentUserId: currentUserId!,
                lastVisibleDocument: _lastVisibleDocument,
                limit: 10,
              );
          sourcedFromRepo = true;
          print(
            "FeedProvider: Fetched batch size from repo: ${fetchedBatch.length}",
          );

          if (fetchedBatch.isEmpty) {
            _hasMoreGarments = false; // El repositorio ya no devuelve más
            print(
              "FeedProvider: Repo returned empty. _hasMoreGarments set to false.",
            );
            // No 'break' aquí, el 'while' evaluará la condición de nuevo.
            // Si newGarmentsForFeed sigue siendo < minBatchSize y el buffer está vacío, el bucle terminará.
          } else {
            // Actualizar el último documento visible para la siguiente paginación
            _lastVisibleDocument = await _getDocSnapshotForGarment(
              fetchedBatch.last.id,
            );
            candidatesToFilter.addAll(
              fetchedBatch,
            ); // Estas son las prendas a filtrar del repo
          }
        }

        // 4. Filtrar las prendas obtenidas del repositorio (si se obtuvieron)
        if (sourcedFromRepo && candidatesToFilter.isNotEmpty) {
          print(
            "FeedProvider: Filtering ${candidatesToFilter.length} candidates from repo.",
          );
          for (GarmentModel garmentFromRepo in candidatesToFilter) {
            // Filtrar por vistas (liked/disliked)
            if (!_likedGarmentIds.contains(garmentFromRepo.id) &&
                !_dislikedGarmentIds.contains(garmentFromRepo.id)) {
              // Prenda válida
              if (newGarmentsForFeed.length < minBatchSize) {
                newGarmentsForFeed.add(garmentFromRepo);
              } else {
                // Ya tenemos suficientes para el lote, el resto de prendas VÁLIDAS del repo van al buffer
                _buffer.add(garmentFromRepo);
              }
            } else {
              print(
                "FeedProvider: Garment ${garmentFromRepo.id} from repo already seen.",
              );
            }
          }
          print(
            "FeedProvider: After repo processing. newGarmentsForFeed: ${newGarmentsForFeed.length}, new buffer size: ${_buffer.length}",
          );
        }

        // Condición de seguridad para salir si no se pueden obtener más prendas
        // Esto es si el buffer está vacío, el repo no tiene más, y no se ha alcanzado alcanzado minBatchSize
        if (newGarmentsForFeed.length < minBatchSize &&
            !_hasMoreGarments &&
            _buffer.isEmpty) {
          print(
            "FeedProvider: While loop breaking. Not enough garments and no more sources.",
          );
          break;
        }
      } // Fin del while
      _garments = newGarmentsForFeed;
      _errorMessage = null;

      if (_garments.isEmpty && !_hasMoreGarments && _buffer.isEmpty) {
        print(
          "FeedProvider: fetchMoreGarments - No valid new garments found AND no more soruces.",
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      print("FeedProvider Error: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
      print(
        "FeedProvider: fetchMoreGarments finished. isLoading: $_isLoading, garments: ${_garments.length}, buffer: ${_buffer.length}, hasMore: $_hasMoreGarments",
      );
    }
  }

  Future<void> swipeRight(GarmentModel garment) async {
    if (currentUserId == null || _currentUserModel == null) {
      return;
    }

    print("FeedProvider: swipeRight on ${garment.name}");
    try {
      // 1. Registrar el like en el repositorio
      await _feedRepository.likeGarment(
        likerUserId: currentUserId!,
        likedGarmentId: garment.id,
        likedGarmentOwnerId: garment.ownerId,
      );

      // 2. Añadir a la lista local de likes para no volver a mostrarla
      _likedGarmentIds.add(garment.id);

      // 3.  Persistir este cambio en _likedGarmentIds en Firestore para el usuario
      await _profileRepository.addLikedGarmentToMyProfile(
        currentUserId: currentUserId!,
        likedGarmentId: garment.id,
      );

      // 4. Notificar al usuario de que han dado like a su prenda
      final String senderUsername = _currentUserModel!.atUsernameHandle;
      final String? senderPhotoUrl = _currentUserModel!.photoUrl;

      final likeNotification = NotificationModel(
        id: '',
        recipientId: garment.ownerId,
        type: NotificationType.like,
        relatedUserId: currentUserId,
        relatedUserName: senderUsername,
        relatedUserPhotoUrl: senderPhotoUrl,
        relatedGarmentId: garment.id,
        relatedGarmentName: garment.name,
        relatedGarmentImageUrl:
            garment.imageUrls.isNotEmpty ? garment.imageUrls[0] : null,
        entityId: garment.id,
        createdAt: Timestamp.now(),
      );

      await _notificationRepository.createNotification(likeNotification);

      // 5. Comprobar si hay match
      final MatchModel? match = await _matchRepository.checkForAndCreateMatch(
        likerUserId: currentUserId!,
        likedGarmentOwnerId: garment.ownerId,
        likedGarmentId: garment.id,
      );

      if (match != null) {
        final Duration timeSinceCreation = DateTime.now().difference(
          match.createdAt.toDate(),
        );
        final bool isNewlyCreated = timeSinceCreation.inSeconds < 2;

        // Solo notificar si es un nuevo match o si es un match antiguo que se había completado y hay un nuevo match entre los usuarios
        if (match.matchStatus == MatchStatus.completed ||
            (isNewlyCreated && match.matchStatus == MatchStatus.active)) {
          print("FeedProvider: ¡ES UN MATCH! ID: ${match.id}");
          // Notificación para el usuario actual (likerUserId)
          final matchNotificationForLiker = NotificationModel(
            id: '',
            recipientId: currentUserId!,
            type: NotificationType.match,
            relatedUserId: garment.ownerId,
            relatedUserName: garment.ownerUsername,
            relatedUserPhotoUrl: garment.ownerPhotoUrl,
            createdAt: Timestamp.now(),
          );
          await _notificationRepository.createNotification(
            matchNotificationForLiker,
          );

          // Notificación para el dueño de la prenda (likedGarmentOwnerId)
          final matchNotificationForOwner = NotificationModel(
            id: '',
            recipientId: garment.ownerId,
            type: NotificationType.match,
            relatedUserId: currentUserId,
            relatedUserName: senderUsername,
            relatedUserPhotoUrl: senderPhotoUrl,
            createdAt: Timestamp.now(),
          );
          await _notificationRepository.createNotification(
            matchNotificationForOwner,
          );
        }

        // TODO: Opcionalmente, mostrar un feedback de match inmediato en la UI del FeedScreen.
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      // ¿Volver a añadir la prenda a la lista si el like falla?
    } finally {
      notifyListeners();
    }
  }

  Future<void> swipeLeft(GarmentModel garment) async {
    if (currentUserId == null) return;
    print("FeedProvider: swipeLeft on ${garment.name}");

    try {
    
      // 1. Registrar el dislike en el repositorio del perfil
      await _profileRepository.addDislikedGarmentToMyProfile(
        currentUserId: currentUserId!,
        dislikedGarmentId: garment.id,
      );

      // 2. Añadir a la lista local de dislikes
      _dislikedGarmentIds.add(garment.id);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
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
    if (currentUserId == null || currentUserId!.isEmpty) {
      // No intentar cargar si no hay ID
      _likedGarmentIds = {};
      _dislikedGarmentIds = {};
      print(
        "FeedProvider: Skipping _loadUserInteractions, currentUserId is empty.",
      );
      return;
    }
    print("FeedProvider: Loading user interactions for $currentUserId");
    try {
      // Cargar IDs de prendas likeadas por el usuario
      _likedGarmentIds = await _profileRepository.getMyLikedGarmentIds(
        currentUserId!,
      );

      // Cargar IDs de prendas dislikeadas por el usuario

      _dislikedGarmentIds = await _profileRepository.getMyDislikedGarmentIds(
        currentUserId!,
      );
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
