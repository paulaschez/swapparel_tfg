class AppRoutes {
  // Rutas de autenticacion
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Rutas Principales de la app (tras autenticarse)
  static const String home = '/home'; //MainAppScreen

  static const String profile = '/profile/:userId'; 
  static const String editProfile = '/edit-profile'; 
  static const String garmentDetail = '/garment/:garmentId'; 
  static const String addGarment = '/add-garment';
  static const String editGarment = '/garment/:garmentId/edit';
  static const String chatConversation = '/chats/:chatId';
  static const String createOffer = '/create-offer/:matchId';

}