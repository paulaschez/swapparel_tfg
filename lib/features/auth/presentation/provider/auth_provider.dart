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
    // Escucha cambios en el estado de autenticación de Firebase
    _authRepository.authStateChanges.listen((User? firebaseUser) async {
      print(
        "AuthProviderC Listen (authStateChanges): Received FirebaseUser: ${firebaseUser?.uid}",
      );

      bool newAuthStatus = firebaseUser != null;
      // Actualiza el estado de autenticacion si ha cambiado
      if (isAuthenticatedNotifier.value != newAuthStatus) {
        isAuthenticatedNotifier.value = newAuthStatus;
      }

      if (newAuthStatus) {
        // Usuario autenticado
        if (_previousFirebaseUserId != firebaseUser.uid) {
          print(
            "AuthProviderC Listen: Fetching UserModel for ${firebaseUser.uid}",
          );
          await _fetchAndSetCurrentUserModel(firebaseUser.uid);
          _previousFirebaseUserId = firebaseUser.uid;
        }
      } else {
        // Usuario no autenticado
        print("AuthProviderC Listen: User is null. Clearing UserModel.");
        if (_currentUserModel != null) {
          _currentUserModel = null;
          _previousFirebaseUserId = null;
          notifyListeners();
        }
      }
    });

    // Si ya hay un usuario autenticado al iniciar, cargar su UserModel
    if(isAuthenticatedNotifier.value && _authRepository.currentUserId != null) {
      _previousFirebaseUserId = _authRepository.currentUserId;
      _fetchAndSetCurrentUserModel(_authRepository.currentUserId!);
    }
  }

  // User? get firebaseUser => _authRepository.currentUser;
  String? get currentUserId => _authRepository.currentUserId;
  bool get isAuthenticated => isAuthenticatedNotifier.value;
  UserModel? get currentUserModel => _currentUserModel;

  // Estados internos
  bool _isLoading = false;
  String? _errorMessage;

  // Getters para la UI
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Metodo SignUp
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    bool success = false;

    try {
      final bool emailExists = await _authRepository.checkIfEmailExists(email);
      if (emailExists) {
        _setError(
          "Este correo electrónico ya está registrado en nuestra base de datos.",
        );
        _setLoading(false);
        return false;
      }
      // Llama al metodo del repositorio
      final userCredential = await _authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
        name: name,
      );
      success = userCredential != null;

      if (success && userCredential.user != null) {
        print(
          "AuthProviderC: SignUp success, currentUser: ${_authRepository.currentUser?.uid}",
        );
      } else if (!success && _errorMessage == null) {
        _setError("Fallo el registro.");
      }
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthExceptionMessage(e));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }

    return success;
  }

  // Metodo SignIn
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    bool success = false;
    try {
      // Llama al metodo del repositorio
      final userModel = await _authRepository.signInWithEmailPassword(
        email,
        password,
      );

      success = userModel != null;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthExceptionMessage(e));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
    return success;
  }

  // Método ResetPassword
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    bool success = false;
    try {
      await _authRepository.sendPasswordResetEmail(email: email);
      success = true; // Asumimos éxito si no hay excepción
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthExceptionMessage(e));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
    return success;
  }

  // Metodo SignOut
  Future<void> signOut() async {
    _setLoading(true);
    await _authRepository.signOut();
    _setLoading(false);
  }

  // --- Métodos privados para actualizar estado y notificar ---
  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null; // Limpia errores al iniciar carga
    notifyListeners(); // Notifica a la UI que el estado cambió
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners(); // Notifica a la UI que hubo un error
  }

  // --- Helper para mapear errores de Firebase Auth ---
  String _mapFirebaseAuthExceptionMessage(FirebaseAuthException e) {
    if (e.code == 'weak-password') {
      return "Password Provided is too weak";
    } else if (e.code == 'email-already-in-use') {
      return "Account already exists";
    } else if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
      return "Invalid email or password.";
    } // Cambiado para SignIn
    else if (e.code == 'wrong-password') {
      return "Wrong Password Provided by User";
    } // Específico de SignIn
    else if (e.code == 'invalid-email') {
      return "The email address is badly formatted.";
    } else {
      return "An error occurred: ${e.code}";
    } // Error genérico de Auth
  }

  Future<void> _fetchAndSetCurrentUserModel(String userId) async {
    UserModel? oldModel = _currentUserModel;

    try {
      _currentUserModel = await _authRepository.getCurrentUserModel();
      print(
        "AuthProviderC: UserModel fetched/updated: ${_currentUserModel?.name}",
      );
    } catch (e) {
      print("AuthProviderC: Error fetching UserModel: $e");
      _currentUserModel = null;
      _setError("No se pudieron cargar los datos del perfil del usuario.");
    }

    if (_errorMessage != null &&
        (oldModel?.id != _currentUserModel?.id ||
            (oldModel == null && _currentUserModel != null) ||
            (oldModel != null && _currentUserModel == null))) {
      // Si el modelo cambio
      notifyListeners();
    } else if (_errorMessage == null &&
        _currentUserModel != null &&
        oldModel != null &&
        oldModel.toJson().toString() !=
            _currentUserModel!.toJson().toString()) {
      // Si el id es el mismo pero otros campos cambiaron
      notifyListeners();
    }
  }

  Future<void> reloadCurrentUserModel() async {
    if (currentUserId != null) {
      print("AuthProviderC: Forcing reload of UserModel for $currentUserId");
      _setLoading(true);
      await _fetchAndSetCurrentUserModel(currentUserId!);
      _setLoading(false);

      print("AuthProviderC: Cannot reload UserModel, no current user.");
    }
  }
}
