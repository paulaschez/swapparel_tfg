// ignore_for_file: avoid_print

import 'package:swapparel/app/config/routes/app_router.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/feed/data/repositories/feed_repository.dart';
import 'package:swapparel/features/feed/presentation/provider/feed_provider.dart';
import 'package:swapparel/features/profile/data/repositories/profile_repository.dart';
import 'package:swapparel/features/profile/presentation/provider/profile_provider.dart';
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

  runApp(const MyAppInitializer());
}

class MyAppInitializer extends StatelessWidget {
  const MyAppInitializer({super.key});

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
        ChangeNotifierProvider<ProfileProvider>(
          create:
              (context) => ProfileProvider(
                profileRepository: context.read<ProfileRepository>(),
              ),
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
      child: const MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    // Obtiene la instancia de AuthProviderC despues de que MultiProvider la haya creado
    final authProvider = Provider.of<AuthProviderC>(context, listen: false);
    _appRouter = AppRouter(authProvider: authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EcoSwap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _appRouter.router,
    );
  }
}

/*

// Widget para decidir si mostrar Login o Home basado en Auth

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

 class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    print('AuthWrapper: initState called');
  }

  @override
  Widget build(BuildContext context) {
    print("AuthWrapper: Build method called");
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ); // Esperando conexión
        }

         if (snapshot.hasError) {
        print("AuthWrapper StreamBuilder: Error in stream: ${snapshot.error}");
        return const Scaffold(body: Center(child: Text("Error de autenticación")));
      }
        if (snapshot.hasData && snapshot.data != null) {
          print(
            "AuthWrapper StreamBuilder: User is logged in! UID: ${snapshot.data!.uid}. Navigating to MainAppScreen.",
          );
          // Usuario está logueado
          return MainAppScreen();
        } else {
          print(
            "AuthWrapper StreamBuilder: No user / User is null. Navigating to SignIn.",
          );
          // Usuario no está logueado
          return const SignIn();
        }
      },
    );
  }
}
 */
