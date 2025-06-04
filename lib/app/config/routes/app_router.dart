import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swapparel/features/garment/presentation/screens/add_edit_garment_screen.dart';
import 'package:swapparel/features/garment/presentation/screens/garment_detail_screen.dart';
import 'package:swapparel/features/inbox/chat/presentation/screens/chat_screen.dart';
import 'package:swapparel/features/offer/presentation/screens/create_offer_screen.dart';
import 'package:swapparel/features/profile/presentation/screens/profile_screen.dart';

import '../../../features/auth/presentation/provider/auth_provider.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/auth/presentation/screens/register_screen.dart';
import '../../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../presentation/main_app_screen.dart';
import '../../../features/profile/presentation/screens/edit_profile_screen.dart';

import 'app_routes.dart';

class AppRouter {
  final AuthProviderC authProvider;
  AppRouter({required this.authProvider});
  late final GoRouter router = GoRouter(
    refreshListenable: authProvider.isAuthenticatedNotifier,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final bool isAuthenticated = authProvider.isAuthenticated;
      final String currentLocation = state.matchedLocation;
      final bool isGoingToAuthRoute =
          currentLocation == AppRoutes.login ||
          currentLocation == AppRoutes.register ||
          currentLocation == AppRoutes.forgotPassword;

      print(
        "GoRouter Redirect: isAuthenticated: $isAuthenticated, Location: $currentLocation, IsAuthRoute: $isGoingToAuthRoute",
      );

      // Si el usuario no esta autenticado y esta intentando ir a una ruta que no es de autenticacion
      if (!isAuthenticated && !isGoingToAuthRoute) {
        print(
          "GoRouter Redirect: Not authenticated, redirecting to ${AppRoutes.login}",
        );
        return AppRoutes.login;
      }

      // Si el usuario si esta autenticado y esta en una ruta de autenticacion
      if (isAuthenticated && isGoingToAuthRoute) {
        print(
          "GoRouter Redirect: Authenticated but on auth route, redirecting to ${AppRoutes.home}",
        );
        return AppRoutes.home;
      }

      // En cualquier otro caso, no redirigir
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final isAuthenticated = authProvider.isAuthenticated;
          return isAuthenticated ? AppRoutes.home : AppRoutes.login;
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainAppScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.addGarment,
        name: 'addGarment',
        builder: (context, state) => AddEditGarmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.garmentDetail,
        name: 'garmentDetail',
        builder: (context, state) {
          final String garmentId = state.pathParameters['garmentId']!;
          return GarmentDetailScreen(garmentId: garmentId);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) {
          final String userId = state.pathParameters['userId']!;
          return ProfileScreen(
            viewingUserId: userId,
            isCurrentUserProfile:
                false, // false porque solo se llama desde el feed / prenda detalle (de prenda ajena)
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editGarment,
        name: 'editGarment',
        builder: (context, state) {
          final String garmentId = state.pathParameters['garmentId']!;

          return AddEditGarmentScreen(garmentIdForEditing: garmentId);
        },
      ),

      // En AppRouter.dart
      GoRoute(
        path: AppRoutes.chatConversation,
        name: 'chatConversation',
        builder: (context, state) {
          final String chatId = state.pathParameters['chatId']!;
          final Map<String, dynamic>? extraData =
              state.extra as Map<String, dynamic>?;

          return ChatScreen(
            chatId: chatId,

            otherUserName: extraData?['otherUserName'] as String? ?? "Chat",
            otherUserPhotoUrl: extraData?['otherUserPhotoUrl'] as String?,
            otherUserId: extraData?['otherUserId'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createOffer,
        name: 'createOffer',
        builder: (context, state) {
          final String matchId = state.pathParameters['matchId']!;
          final Map<String, dynamic>? extraData =
              state.extra as Map<String, dynamic>?;
          final String offeringUserId = extraData?['offeringUserId'] as String;
          final String receivingUserId =
              extraData?['receivingUserId'] as String;
          final String? receivingUsername =
              extraData?['receivingUsername'] as String?;

          return CreateOfferScreen(
            matchId: matchId,
            offeringUserId: offeringUserId,
            receivingUserId: receivingUserId,
            receivingUsername:
                receivingUsername ?? "Usuario", // Fallback si es null
          );
        },
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Página no encontrada: ${state.error}')),
        ),
  );
}
