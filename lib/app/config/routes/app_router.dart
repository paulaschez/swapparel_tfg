// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swapparel/features/garment/presentation/screens/add_garment_screen.dart';

import '../../../features/auth/presentation/provider/auth_provider.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/auth/presentation/screens/register_screen.dart';
import '../../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../presentation/main_app_screen.dart';
import '../../../features/profile/presentation/screens/edit_profile_screen.dart';
// TODO: Importar el resto de pantallas (cuando las tenga)

import 'app_routes.dart';

class AppRouter {
  final AuthProviderC authProvider;
  AppRouter({required this.authProvider});
  late final GoRouter router = GoRouter(
    refreshListenable: authProvider.isAuthenticatedNotifier,
    initialLocation: AppRoutes.splash,
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
        builder: (context, state) => const SignIn(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const SignUp(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPassword(),
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
        builder: (context, state) => const AddGarmentScreen(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Página no encontrada: ${state.error}')),
        ),
  );
}
