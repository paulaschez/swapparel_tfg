import 'package:chat_app/app/presentation/main_app_screen.dart';
import 'package:chat_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:chat_app/features/auth/presentation/screens/login_screen.dart';
import 'package:chat_app/features/feed/data/repositories/feed_repository.dart';
import 'package:chat_app/features/feed/presentation/provider/feed_provider.dart';
import 'package:chat_app/features/profile/data/repositories/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app/config/theme/app_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'core/services/local_storage_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Singleton de FirebaseAuth, Firestore, FirebaseStorage y almacenamiento local
        Provider<FirebaseAuth>(create: (_) => FirebaseAuth.instance),
        Provider<FirebaseFirestore>(create: (_) => FirebaseFirestore.instance),
        Provider<ILocalStorageService>(
          create: (_) => LocalStorageServiceImpl(),
        ),
        Provider<FirebaseStorage>(create: (_) => FirebaseStorage.instance),

        // Repositorios (Depende de los servicios anteriores)
        ProxyProvider3<
          FirebaseAuth,
          FirebaseFirestore,
          ILocalStorageService,
          AuthRepository
        >(
          update:
              (_, auth, firestore, storageService, __) => AuthRepositoryImpl(
                firebaseAuth: auth,
                firestore: firestore,
                localStorageService: storageService,
              ),
        ),

        ProxyProvider2<FirebaseFirestore, FirebaseStorage, ProfileRepository>(
          update:
              (_, firestore, storage, __) =>
                  ProfileRepositoryImpl(firestore: firestore, storage: storage),
        ),

        ProxyProvider<FirebaseFirestore, FeedRepository>(
          update:
              (_, firestore, __) => FeedRepositoryImpl(firestore: firestore),
        ),

        // ChangeNotifierProviders
        ChangeNotifierProvider<AuthProviderC>(
          create:
              (context) =>
                  AuthProviderC(authRepository: context.read<AuthRepository>()),
        ),
        ChangeNotifierProxyProvider<AuthProviderC, FeedProvider>(
          create: (context) {
            final authProvider = context.read<AuthProviderC>();
            return FeedProvider(
              feedRepository: context.read<FeedRepository>(),
              profileRepository: context.read<ProfileRepository>(),
              currentUserId: authProvider.currentUserId ?? '',
            );
          },
          update: (context, authProvider, previousFeedProvider) {
            final newUserId = authProvider.currentUserId ?? '';
            if (previousFeedProvider == null ||
                previousFeedProvider.currentUserId != newUserId) {
              print(
                "FeedProvider: Creando / Recreando para userId: $newUserId",
              );
              return FeedProvider(
                feedRepository: context.read<FeedRepository>(),
                currentUserId: newUserId,
                profileRepository: context.read<ProfileRepository>(),
              );
            } else {
              print(
                "FeedProvider: Reutilizando instancia anterior, userId no cambió.",
              );
              return previousFeedProvider;
            }
          },
        ),
      ],
      child: MaterialApp(
        title: 'EcoSwap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: MainAppScreen(),
      ),
    );
  }
}

// Widget para decidir si mostrar Login o Home basado en Auth
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ); // Esperando conexión
        }
        if (snapshot.hasData) {
          // Usuario está logueado
          return MainAppScreen();
        } else {
          // Usuario no está logueado
          return SignIn();
        }
      },
    );
  }
}
