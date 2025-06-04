import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swapparel/features/auth/data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProviderC extends ChangeNotifier {
  final AuthRepository _authRepository;
  UserModel? _currentUserModel;
  String? _previousFirebaseUserId;
  final ValueNotifier<bool> isAuthenticatedNotifier;

  AuthProviderC({required AuthRepository authRepository})
      : _authRepository = authRepository,
        isAuthenticatedNotifier = ValueNotifier<bool>(
          authRepository.currentUser != null,
        ) {
    _authRepository.authStateChanges.listen((User? firebaseUser) async {
      print(
        "AuthProviderC Listen (authStateChanges): Received FirebaseUser: ${firebaseUser?.uid}",
      );

      bool newAuthStatus = firebaseUser != null;
      if (isAuthenticatedNotifier.value != newAuthStatus) {
        isAuthenticatedNotifier.value = newAuthStatus;
      }

      if (newAuthStatus) {
        if (_previousFirebaseUserId != firebaseUser.uid || _currentUserModel == null) { // Añadido _currentUserModel == null para cargar si no existe
          print(
            "AuthProviderC Listen: Fetching UserModel for ${firebaseUser.uid}",
          );
          await _fetchAndSetCurrentUserModel(firebaseUser.uid);
          _previousFirebaseUserId = firebaseUser.uid;
        }
      } else {
        print("AuthProviderC Listen: User is null. Clearing UserModel.");
        if (_currentUserModel != null || _previousFirebaseUserId != null) { // Solo limpiar y notificar si había algo
          _currentUserModel = null;
          _previousFirebaseUserId = null;
          notifyListeners();
        }
      }
    });

    if (isAuthenticatedNotifier.value && _authRepository.currentUserId != null) {
      _previousFirebaseUserId = _authRepository.currentUserId;
      _fetchAndSetCurrentUserModel(_authRepository.currentUserId!);
    }
  }

  String? get currentUserId => _authRepository.currentUserId;
  bool get isAuthenticated => isAuthenticatedNotifier.value;
  UserModel? get currentUserModel => _currentUserModel;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- Métodos de Autenticación ---
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final bool emailExists = await _authRepository.checkIfEmailExists(email.trim());
      if (emailExists) {
        _setError("Este correo electrónico ya está registrado.");
        return false; 
      }

      final userCredential = await _authRepository.signUpWithEmailPassword(
        email: email.trim(),
        password: password.trim(),
        name: name.trim(),
      );

      if (userCredential?.user != null) {
        print("AuthProviderC: SignUp success, waiting for authStateChanges to fetch UserModel.");
        _setError(null); 
        return true;
      } else {

        if (_errorMessage == null) _setError("El registro falló por un motivo desconocido.");
        return false;
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException en signUp: ${e.code} - ${e.message}");
      _setError(_mapFirebaseAuthExceptionMessage(e));
      return false;
    } catch (e) {
      print("Error genérico en signUp: $e");
      _setError("Ocurrió un error inesperado durante el registro.");
      return false;
    } finally {
      _setLoading(false); 
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      final userModel = await _authRepository.signInWithEmailPassword(
        email.trim(),
        password.trim(),
      );

      if (userModel != null) {
        print("AuthProviderC: SignIn success, waiting for authStateChanges to fetch UserModel.");
        _setError(null);
        return true;
      } else {
        if (_errorMessage == null) _setError("El inicio de sesión falló por un motivo desconocido.");
        return false;
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException en signIn: ${e.code} - ${e.message}");
      _setError(_mapFirebaseAuthExceptionMessage(e));
      return false;
    } catch (e) {
      print("Error genérico en signIn: $e");
      _setError("Ocurrió un error inesperado. Por favor, inténtalo de nuevo.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    try {
      await _authRepository.sendPasswordResetEmail(email: email.trim());
      _setError(null); 
      return true;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException en resetPassword: ${e.code} - ${e.message}");
      _setError(_mapFirebaseAuthExceptionMessage(e));
      return false;
    } catch (e) {
      print("Error genérico en resetPassword: $e");
      _setError("Ocurrió un error al intentar enviar el correo de restablecimiento.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true); // Opcional: mostrar loading durante el signOut
    await _authRepository.signOut();
   
    _setLoading(false);
  }

  // --- Métodos privados ---
  void _setLoading(bool value) {
    if (_isLoading == value) return; 
    _isLoading = value;
    if (value) {
      _errorMessage = null; 
    }
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
  
    notifyListeners();
  }

  String _mapFirebaseAuthExceptionMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta de usuario ha sido deshabilitada.';
      case 'user-not-found':
        return 'No se encontró un usuario con este correo electrónico.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'invalid-credential': 
        return 'Correo electrónico o contraseña incorrectos. Verifica tus datos.';
      case 'email-already-in-use':
        return 'Este correo electrónico ya está en uso por otra cuenta.';
      case 'operation-not-allowed':
        return 'Esta operación no está permitida. Contacta a soporte.';
      case 'weak-password':
        return 'La contraseña es demasiado débil. Debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Has intentado iniciar sesión demasiadas veces. Por favor, inténtalo más tarde o restablece tu contraseña.';
      case 'network-request-failed':
        return 'Error de red. Por favor, verifica tu conexión e inténtalo de nuevo.';
      case 'missing-email':
        return 'Por favor, introduce tu correo electrónico.';
      default:
        print("Código de error no mapeado de FirebaseAuth: ${e.code}"); 
        return 'Ocurrió un error (${e.code}). Inténtalo de nuevo.';
    }
  }

  Future<void> _fetchAndSetCurrentUserModel(String userId) async {
    UserModel? previousModel = _currentUserModel;
    String? previousError = _errorMessage;

    try {
      _currentUserModel = await _authRepository.getCurrentUserModel(); 
      if (_currentUserModel == null && userId.isNotEmpty) {
          print("AuthProviderC WARN: Firebase user $userId exists, but UserModel is null from repository.");
          _setError("No se pudieron cargar los datos de tu perfil. Intenta reiniciar la app.");
      } else {
        print("AuthProviderC: UserModel fetched/updated: ${_currentUserModel?.name}");
        if(previousError != null) _setError(null); 
      }
    } catch (e) {
      print("AuthProviderC: Error fetching UserModel: $e");
      _currentUserModel = null; 
      _setError("No se pudieron cargar los datos de tu perfil.");
    }

    bool modelChanged = previousModel?.id != _currentUserModel?.id ||
                       (previousModel == null && _currentUserModel != null) ||
                       (previousModel != null && _currentUserModel == null) ||
                       (previousModel != null && _currentUserModel != null && previousModel.toJson().toString() != _currentUserModel!.toJson().toString());

    if (modelChanged || _errorMessage != previousError) {
      notifyListeners();
    }
  }

  Future<void> reloadCurrentUserModel() async {
    if (currentUserId != null) {
      print("AuthProviderC: Forcing reload of UserModel for $currentUserId");
      _setLoading(true); // Mostrar loading
      await _fetchAndSetCurrentUserModel(currentUserId!);
      _setLoading(false); // Quitar loading
    } else {
      print("AuthProviderC: Cannot reload UserModel, no current user.");
    }
  }
}