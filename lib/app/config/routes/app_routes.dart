class AppRoutes {
  // Rutas de autenticacion
  static const String splash = '/'; //TODO HACER PANTALLA SPLASH
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Rutas Principales de la app (tras autenticarse)
  static const String home = '/home'; //MainAppScreen

  // Rutas de Detalle (AÑADIR A MEDIDA QUE SE NECESITEN)
  static const String profile = '/profile/:userId'; 
  static const String editProfile = '/edit-profile'; 
  static const String garmentDetail = '/garment/:garmentId'; 
  static const String addGarment = '/add-garment';

}