import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProviderC extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProviderC({required AuthRepository authRepository})
    : _authRepository = authRepository {
    _authRepository.authStateChanges.listen((User? user) {
      print("AuthProviderC: Auth state changed. User: ${user?.uid}");
      notifyListeners();
    });
  }

  User? get currentUser => _authRepository.currentUser;
  String? get currentUserId => _authRepository.currentUserId;
  bool get isAuthenticated => _authRepository.currentUser != null;

  // Estados internos
  bool _isLoading = false;
  String? _errorMessage;

  // Getters para la UI
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Metodos para llamar desde la UI

  // Metodo SignUp
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    _setLoading(true);
    bool success = false;
   
    try {
      // Llama al metodo del repositorio
      final userCredential = await _authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
        username: username,
      );
      success = userCredential != null;

      if (success) {
        print(
          "AuthProviderC: SignUp success, currentUser: ${_authRepository.currentUser?.uid}",
        );
       
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
    await _authRepository.signOut();
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
}
