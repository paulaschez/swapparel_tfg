
import 'package:swapparel/core/constants/firestore_collections.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:swapparel/core/constants/firestore_user_fields.dart';
import 'package:uuid/uuid.dart';

abstract class AuthRepository {
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  });

  Future<UserModel?> signInWithEmailPassword(String email, String password);

  Future<void> sendPasswordResetEmail({required String email});
  Future<bool> checkIfEmailExists(String email);
  Future<void> signOut();
  Stream<User?>
  get authStateChanges; // Para saber si el usuario está logueado ya
  Future<UserModel?> getCurrentUserModel();
  User? get currentUser; // Para obtener el usuario actual de forma síncrona
  String? get currentUserId; // Para obtener el UID actual de forma síncrona
}

class AuthRepositoryImpl implements AuthRepository {
  // Dependencias
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // Constructor que recibe las dependencias
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  @override
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print("AuthRepo: Attempting Firebase user creation for $email");
      // Crear usuario en Auth
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      print(
        "AuthRepo: Firebase user creation SUCCESSFUL. User UID: ${userCredential.user?.uid}",
      );

      // Si el usuario se creó correctamente
      if (userCredential.user != null) {
        String userId = userCredential.user!.uid;
        String initialUsername =
            email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') +
            const Uuid().v1().substring(0, 4);

        // Crear el UserModel
        final newUser = UserModel(
          id: userId,
          email: email,
          name: name,
          username: initialUsername, // Username generado
          photoUrl: null,
          location: null,
          createdAt: Timestamp.now(),
        );

        // Guardar en Firestore
        await _firestore.collection("users").doc(userId).set(newUser.toJson());

        print("AuthRepo: User data saved to Firestore for UID: $userId");

        return userCredential; // Devuelve el UserCredential si todo fue bien
      }
      print(
        "AuthRepo: userCredential.user was null after creation (should not happen).",
      );
      return null;
    } on FirebaseAuthException catch (e) {
      print("AuthRepo SignUp Error: ${e.code}");
      rethrow;
    } catch (e) {
      print("AuthRepo SignUp General Error: $e");
      throw Exception(
        "Registro exitoso en Auth, pero falló al guardar datos del perfil.",
      );
    }
  }

  @override
  Future<UserModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      // Autenticar con Firebase Auth
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        String userId = userCredential.user!.uid;

        // Obtener datos del usuario desde Firestore
        final docSnapshot =
            await _firestore.collection("users").doc(userId).get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          final userModel = UserModel.fromFirestore(docSnapshot);

          return userModel;
        } else {
          print(
            "AuthRepo SignIn Warning: User $userId authenticated but no data found.",
          );
          await _firebaseAuth.signOut(); // Cierra sesión si no hay datos
          throw Exception("User data not found after login.");
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print("AuthRepo SignIn Error: ${e.code}");
      
      rethrow;
    } catch (e) {
      print("AuthRepo SignIn General Error: $e");
      throw Exception("Failed to complete sign in process.");
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<UserModel?> getCurrentUserModel() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    try {
      final docSnapshot =
          await _firestore
              .collection(usersCollection)
              .doc(firebaseUser.uid)
              .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserModel.fromFirestore(docSnapshot);
      } else {
        print(
          "Warning: User ${firebaseUser.uid} authenticated but no data found in Firestore.",
        );
        return null;
      }
    } catch (e) {
      print("Error fetching current user data: $e");
      return null;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("AuthRepo ResetPassword Error: ${e.code}");
      rethrow; // Para que la UI sepa el error ('user-not-found')
    } catch (e) {
      print("AuthRepo ResetPassword General Error: $e");
      throw Exception("Failed to send password reset email.");
    }
  }

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  @override
  Future<bool> checkIfEmailExists(String email) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(usersCollection)
              .where(emailField, isEqualTo: email.trim())
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        print("AuthRepo: Email '$email' SÍ existe en Firestore.");
        return true; // El email existe
      } else {
        print("AuthRepo: Email '$email' NO existe en Firestore.");
        return false; // El email no existe
      }

    } catch (e) {
       print("AuthRepo Error - checkIfEmailExists: $e");
      return false;
    }
  }
}
