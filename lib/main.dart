import 'package:swapparel/app/config/routes/app_router.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/feed/data/repositories/feed_repository.dart';
import 'package:swapparel/features/feed/presentation/provider/feed_provider.dart';
import 'package:swapparel/features/garment/data/repositories/garment_repository.dart';
import 'package:swapparel/features/garment/presentation/provider/garment_detail_provider.dart';
import 'package:swapparel/features/garment/presentation/provider/garment_provider.dart';
import 'package:swapparel/features/inbox/chat/data/repositories/chat_repository.dart';
import 'package:swapparel/features/inbox/chat/presentation/provider/chat_detail_provider.dart';
import 'package:swapparel/features/inbox/chat/presentation/provider/chat_list_provider.dart';
import 'package:swapparel/features/match/presentation/provider/match_provider.dart';
import 'package:swapparel/features/offer/presentation/provider/offer_provider.dart';
import 'package:swapparel/features/match/data/repositories/match_repository.dart';
import 'package:swapparel/features/inbox/notification/data/repositories/notification_repository.dart';
import 'package:swapparel/features/inbox/notification/presentation/provider/notification_provider.dart';
import 'package:swapparel/features/offer/data/repositories/offer_repository.dart';
import 'package:swapparel/features/profile/data/repositories/profile_repository.dart';
import 'package:swapparel/features/profile/presentation/provider/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swapparel/features/rating/data/repositories/rating_repository.dart';
import 'package:swapparel/features/rating/presentation/provider/rating_provider.dart';
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

        ProxyProvider<FirebaseFirestore, NotificationRepository>(
          update:
              (_, firestore, __) =>
                  NotificationRepositoryImpl(firestore: firestore),
        ),
        ProxyProvider2<
          FirebaseFirestore,
          NotificationRepository,
          MatchRepository
        >(
          update:
              (_, firestore, notifRepo, __) => MatchRepositoryImpl(
                firestore: firestore,
                notificationRepository: notifRepo,
              ),
        ),
        ProxyProvider<FirebaseFirestore, ChatRepository>(
          update:
              (_, firestore, __) => ChatRepositoryImpl(firestore: firestore),
        ),
        ProxyProvider<FirebaseFirestore, OfferRepository>(
          update:
              (_, firestore, __) => OfferRepositoryImpl(firestore: firestore),
        ),
        ProxyProvider4<
          FirebaseFirestore,
          ProfileRepository,
          MatchRepository,
          NotificationRepository,
          RatingRepository
        >(
          update:
              (_, firestore, profileRepo, matchRepo, notifRepo, __) =>
                  RatingRepositoryImpl(
                    firestore: firestore,
                    profileRepository: profileRepo,
                    matchRepository: matchRepo,
                    notificationRepository: notifRepo,
                  ),
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
        ChangeNotifierProvider<MatchProvider>(
          create:
              (context) => MatchProvider(
                authProvider: context.read<AuthProviderC>(),
                feedRepository: context.read<FeedRepository>(),
                profileRepository: context.read<ProfileRepository>(),
                matchRepository: context.read<MatchRepository>(),
                notificationRepository: context.read<NotificationRepository>(),
              ),
        ),
        ChangeNotifierProxyProvider<AuthProviderC, FeedProvider>(
          create: (context) {
            return FeedProvider(
              feedRepository: context.read<FeedRepository>(),
              profileRepository: context.read<ProfileRepository>(),
              authProvider: context.read<AuthProviderC>(),
              matchProvider: context.read<MatchProvider>(),
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
                profileRepository: context.read<ProfileRepository>(),
                authProvider: authProvider,
                matchProvider: context.read<MatchProvider>(),
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
                authProvider: context.read<AuthProviderC>(),
                matchProvider: context.read<MatchProvider>(),
              ),
        ),
        

        ChangeNotifierProxyProvider<AuthProviderC, NotificationProvider>(
          create: (context) {
            final auth = context.read<AuthProviderC>();
            return NotificationProvider(
              notificationRepository: context.read<NotificationRepository>(),
              authProvider: auth,
            );
          },
          update: (context, auth, previous) {
            final newActualUserId = auth.currentUserId;

            print("ProxyProvider for Notification: UPDATE called.");
            print("  New Auth User ID from auth parameter: $newActualUserId");
            if (previous != null) {
              print(
                "  Previous NotificationProvider was effective for User ID: ${previous.effectiveUserId}",
              );
            } else {
              print("  Previous NotificationProvider instance is null.");
            }

            if (previous == null ||
                previous.effectiveUserId != newActualUserId) {
              print(
                "  CONDITION MET: Recreating NotificationProvider for actual user: $newActualUserId",
              );
              return NotificationProvider(
                notificationRepository: context.read<NotificationRepository>(),
                authProvider: auth,
              );
            }

            print(
              "  CONDITION NOT MET: Reusing previous NotificationProvider (was effective for ${previous.effectiveUserId}).",
            );
            return previous;
          },
        ),

        ChangeNotifierProxyProvider<AuthProviderC, ChatListProvider>(
          create: (context) {
            final auth = context.read<AuthProviderC>();
            print(
              "ProxyProvider for ChatList: CREATING initial instance for effectiveUser: ${auth.currentUserId}",
            );
            return ChatListProvider(
              matchRepository: context.read<MatchRepository>(),
              authProvider: auth,
            );
          },
          update: (
            BuildContext context,
            AuthProviderC auth,
            ChatListProvider? previous,
          ) {
            final newActualUserId = auth.currentUserId;

            print("ProxyProvider for ChatList: UPDATE called.");
            print("  New Auth User ID from auth parameter: $newActualUserId");
            if (previous != null) {
              print(
                "  Previous ChatListProvider was effective for User ID: ${previous.effectiveUserId}",
              );
            } else {
              print("  Previous ChatListProvider instance is null.");
            }

            if (previous == null ||
                previous.effectiveUserId != newActualUserId) {
              print(
                "  CONDITION MET: Recreating ChatListProvider for actual user: $newActualUserId",
              );
              return ChatListProvider(
                matchRepository: context.read<MatchRepository>(),
                authProvider: auth,
              );
            }

            print(
              "  CONDITION NOT MET: Reusing previous ChatListProvider (was effective for ${previous.effectiveUserId}).",
            );
            return previous;
          },
        ),

        ChangeNotifierProxyProvider3<
          AuthProviderC,
          MatchRepository,
          OfferRepository,
          ChatDetailProvider
        >(
          create: (context) {
            final auth = context.read<AuthProviderC>();
            print(
              "ProxyProvider for ChatDetail: CREATING initial instance for effectiveUser: ${auth.currentUserId}",
            );
            return ChatDetailProvider(
              chatRepository: context.read<ChatRepository>(),
              authProvider: auth,
              matchRepository: context.read<MatchRepository>(),
              offerRepository: context.read<OfferRepository>(),
            );
          },
          update: (
            BuildContext context,
            AuthProviderC auth,
            MatchRepository matchRepo,
            OfferRepository offerRepo,
            ChatDetailProvider? previous,
          ) {
            final newActualUserId = auth.currentUserId;

            print("ProxyProvider for ChatDetail: UPDATE called.");
            print("  New Auth User ID from auth parameter: $newActualUserId");
            if (previous != null) {
              print(
                "  Previous ChatDetailProvider was effective for User ID: ${previous.effectiveUserId}",
              );
            } else {
              print("  Previous ChatDetailProvider instance is null.");
            }
            if (previous == null ||
                previous.effectiveUserId != newActualUserId) {
              print(
                "  CONDITION MET: Recreating ChatDetailProvider for actual user: $newActualUserId",
              );
              return ChatDetailProvider(
                chatRepository: context.read<ChatRepository>(),
                authProvider: auth,
                matchRepository: matchRepo,
                offerRepository: offerRepo,
              );
            }

            print(
              "  CONDITION NOT MET: Reusing previous ChatDetailProvider (was effective for ${previous.effectiveUserId}).",
            );
            return previous;
          },
        ),
        ChangeNotifierProxyProvider6<
          AuthProviderC,
          OfferRepository,
          MatchRepository,
          GarmentRepository,
          ProfileRepository,
          NotificationRepository,
          OfferProvider
        >(
          create:
              (context) => OfferProvider(
                authProvider: context.read<AuthProviderC>(),
                offerRepository: context.read<OfferRepository>(),
                matchRepository: context.read<MatchRepository>(),
                garmentRepository: context.read<GarmentRepository>(),
                profileRepository: context.read<ProfileRepository>(),
                notificationRepository: context.read<NotificationRepository>(),
                firestore: context.read<FirebaseFirestore>(),
              ),
          update: (
            context,
            auth,
            offerRepo,
            matchRepo,
            garmentRepo,
            profileRepo,
            notificationRepo,
            previous,
          ) {
            if (previous == null ||
                auth.currentUserId != previous.authProvider.currentUserId) {
              return OfferProvider(
                authProvider: auth,
                offerRepository: offerRepo,
                matchRepository: matchRepo,
                garmentRepository: garmentRepo,
                profileRepository: profileRepo,
                notificationRepository: notificationRepo,
                firestore: context.read<FirebaseFirestore>(),
              );
            }
            return previous;
          },
        ),
        ChangeNotifierProxyProvider2<
          AuthProviderC,
          ChatDetailProvider,
          RatingProvider
        >(
          create: (context) {
            print("ProxyProvider for Rating: CREATING initial instance.");
            return RatingProvider(
              ratingRepository: context.read<RatingRepository>(),
              authProvider: context.read<AuthProviderC>(),
            );
          },
          update: (
            context,
            auth,
            ChatDetailProvider? chatDetail,
            RatingProvider? previous,
          ) {
            final newActualUserId = auth.currentUserId;
            print(
              "ProxyProvider for Rating: UPDATE called. AuthUser: $newActualUserId",
            );

            if (previous == null ||
                previous.authProvider.currentUserId != newActualUserId) {
              print(
                "  CONDITION MET: Recreating RatingProvider for user: $newActualUserId",
              );
              final newRatingProvider = RatingProvider(
                ratingRepository: context.read<RatingRepository>(),
                authProvider: auth,
              );
              if (chatDetail != null) {
                newRatingProvider.setChatDetailProvider(chatDetail);
              }
              return newRatingProvider;
            } else {
              if (chatDetail != null) {
                previous.setChatDetailProvider(chatDetail);
                print(
                  "  RatingProvider: Updated ChatDetailProvider reference.",
                );
              }
              print("  CONDITION NOT MET: Reusing previous RatingProvider.");
              return previous;
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
      title: 'Swapparel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _appRouter.router,
    );
  }
}
