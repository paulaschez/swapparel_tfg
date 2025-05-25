// ignore_for_file: avoid_print

import 'package:swapparel/app/config/routes/app_router.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/feed/data/repositories/feed_repository.dart';
import 'package:swapparel/features/feed/presentation/provider/feed_provider.dart';
import 'package:swapparel/features/garment/data/repositories/garment_repository.dart';
import 'package:swapparel/features/garment/presentation/provider/garment_detail_provider.dart';
import 'package:swapparel/features/garment/presentation/provider/garment_provider.dart';
import 'package:swapparel/features/match/data/repositories/match_repository.dart';
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

        ProxyProvider2<FirebaseFirestore, FirebaseStorage, GarmentRepository>(
          update:
              (_, firestore, storage, __) =>
                  GarmentRepositoryImpl(firestore: firestore, storage: storage),
        ),

        ProxyProvider<FirebaseFirestore, MatchRepository>(
          update:
              (_, firestore, __) => MatchRepositoryImpl(firestore: firestore),
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
              matchRepository: context.read<MatchRepository>(),
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
                matchRepository: context.read<MatchRepository>(),
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
        ChangeNotifierProxyProvider2<
          AuthProviderC,
          GarmentRepository,
          GarmentProvider
        >(
          create:
              (context) => GarmentProvider(
                garmentRepository: context.read<GarmentRepository>(),
                authProvider: context.read<AuthProviderC>(),
              ),
          update: (
            context,
            authProvider,
            garmentRepo,
            previousGarmentProvider,
          ) {
            if (previousGarmentProvider == null ||
                authProvider.currentUserId !=
                    previousGarmentProvider.authProvider.currentUserId) {
              return GarmentProvider(
                authProvider: authProvider,
                garmentRepository: garmentRepo,
              );
            }
            return previousGarmentProvider;
          },
        ),
        ChangeNotifierProvider<GarmentDetailProvider>(
          create:
              (context) => GarmentDetailProvider(
                garmentRepository: context.read<GarmentRepository>(),
                profileRepository: context.read<ProfileRepository>(),
                feedRepository: context.read<FeedRepository>(),
                authProvider: context.read<AuthProviderC>(),
              ),
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
      title: 'Swapparel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _appRouter.router,
    );
  }
}
