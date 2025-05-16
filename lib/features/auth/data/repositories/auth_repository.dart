import '/../core/services/local_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
  });

  Future<UserModel?> signInWithEmailPassword(String email, String password);

  Future<void> sendPasswordResetEmail({required String email});
  // Future<void> saveNewUserData(String userId, Map<String, dynamic> userData);
  // Future<bool> checkIfEmailExists(String email);
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
  final ILocalStorageService _localStorageService;

  // Constructor que recibe las dependencias
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required ILocalStorageService localStorageService,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _localStorageService = localStorageService;

  @override
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
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
        String defaultPhotoUrl =
            "https://cdn-icons-png.flaticon.com/512/17246/17246491.png";

        // Crear el UserModel
        final newUser = UserModel(
          id: userId,
          email: email,
          name: username,
          displayName: username,
          photoUrl: defaultPhotoUrl,
        );


        // Guardar en Firestore
        await _firestore.collection("users").doc(userId).set(newUser.toJson());

                print("AuthRepo: User data saved to Firestore for UID: $userId");


        // Guardar en SharedPreferences
        await _localStorageService.saveUserId(userId);
        await _localStorageService.saveUserEmail(email);
        await _localStorageService.saveUserName(username);
        await _localStorageService.saveUserDisplayName(username);
        await _localStorageService.saveUserPic(defaultPhotoUrl);

                print("AuthRepo: User data saved to cache for UID: $userId");


        return userCredential; // Devuelve el UserCredential si todo fue bien
      }
      print("AuthRepo: userCredential.user was null after creation (should not happen).");
      return null;
    } on FirebaseAuthException catch (e) {
      print("AuthRepo SignUp Error: ${e.code}");
      rethrow;
    } catch (e) {
      print("AuthRepo SignUp General Error: $e");
      throw Exception("Failed to complete sign up process.");
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

          // Guardar datos en Shared Preferences mediante LocalStorageService
          await _localStorageService.saveUserId(userModel.id);
          await _localStorageService.saveUserEmail(userModel.email);
          await _localStorageService.saveUserName(
            userModel.displayName ?? userModel.name,
          );
          await _localStorageService.saveUserDisplayName(
            userModel.displayName ?? userModel.name,
          );
          await _localStorageService.saveUserPic(userModel.photoUrl ?? '');

          return userModel;
        } else {
          print(
            "AuthRepo SignIn Warning: User $userId authenticated but no data found.",
          );
          await _firebaseAuth.signOut(); // Cierra sesión si no hay datos
          await _localStorageService.clearUserData(); // Limpia caché
          throw Exception("User data not found after login.");
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print("AuthRepo SignIn Error: ${e.code}");
      await _localStorageService
          .clearUserData(); // Limpia caché en error de login
      rethrow;
    } catch (e) {
      print("AuthRepo SignIn General Error: $e");
      await _localStorageService.clearUserData(); // Limpia caché
      throw Exception("Failed to complete sign in process.");
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _localStorageService.clearUserData();
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
          await _firestore.collection("users").doc(firebaseUser.uid).get();
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
}
