import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa si lo vas a usar

class AppColors {
  static const Color primaryGreen = Color(0xFF6d8767); // Verde medio (ej: botones)
  static const Color darkGreen = Color(0xFF1f5014);   // Verde oscuro (ej: texto, iconos activos)
  static const Color lightGreen = Color(0xFFd5dfd2); // Verde muy claro (ej: fondos sutiles, burbujas?)
  static const Color background = Color(0xFFefefe6); // Beige/Crema de fondo
  static const Color surface = Colors.white;        // Blanco para Cards, Dialogs, etc.
  static const Color textPrimary = Color(0xFF1f5014); // Color de texto principal (oscuro)
  static const Color textSecondary = Color(0XFF6d8767);     // Color de texto secundario
  static const Color error = Colors.redAccent;      // Color para errores
  static const Color likeRed = Color(0xFFab4949);   // Rojo/Rosa para el botón 'like' (si es distinto)
}

class AppTheme {
  // Método estático para obtener el tema claro
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryGreen,       // Color principal (botones, FABs, etc.)
        secondary: AppColors.darkGreen,        // Color secundario (a veces para acentos)
        surface: AppColors.background,         // Color de fondo general
        error: AppColors.error,                // Color de error
        onPrimary: Colors.white,               // Color de texto/iconos SOBRE primary
        onSecondary: Colors.white,             // Color de texto/iconos SOBRE secondary
        onSurface: AppColors.textPrimary,      // Color de texto/iconos SOBRE surface
        onError: Colors.white,                 // Color de texto/iconos SOBRE error
        brightness: Brightness.light,
      ),

      // --- Color de Fondo del Scaffold ---
      scaffoldBackgroundColor: AppColors.background,

      // --- Tipografía ---

      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(color: AppColors.textPrimary), // Estilos para títulos grandes, etc.
        displayMedium: GoogleFonts.poppins(color: AppColors.textPrimary),
        displaySmall: GoogleFonts.poppins(color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.poppins(color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.poppins(color: AppColors.textPrimary),
        titleLarge: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold), // Títulos de AppBar, etc.
        titleMedium: GoogleFonts.poppins(color: AppColors.textPrimary),
        titleSmall: GoogleFonts.poppins(color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.poppins(color: AppColors.textPrimary),  // Texto de cuerpo principal
        bodyMedium: GoogleFonts.poppins(color: AppColors.textPrimary), // Texto de cuerpo por defecto
        bodySmall: GoogleFonts.poppins(color: AppColors.textSecondary),// Texto más pequeño o secundario (gris)
        labelLarge: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold), // Texto para botones
        labelSmall: GoogleFonts.poppins(color: AppColors.textSecondary),
      ).apply( // Aplica colores por defecto si no se especifican arriba
         bodyColor: AppColors.textPrimary,
         displayColor: AppColors.textPrimary,
      ),


      // --- Estilos Específicos de Widgets ---

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryGreen, // Fondo como el scaffold
        foregroundColor: AppColors.darkGreen, // Color de iconos y título
        elevation: 1, // Sin sombra
        //centerTitle: true, 
        titleTextStyle: GoogleFonts.poppins( // Asegura el estilo del título
          color: AppColors.background,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // BottomNavigationBar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryGreen, // Fondo verde
        selectedItemColor: AppColors.darkGreen,   // Icono seleccionado (verde oscuro)
        unselectedItemColor: AppColors.darkGreen.withAlpha(155), // Icono no seleccionado (blanco semi-transparente)
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed, // Asegura que todos los items sean visibles
        elevation: 5, 
      ),

       // FloatingActionButton Theme
       floatingActionButtonTheme: FloatingActionButtonThemeData(
         backgroundColor: AppColors.primaryGreen,
         foregroundColor: Colors.white,
       ),

      // ElevatedButton Theme (Para botones principales)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen, // Fondo verde
          foregroundColor: Colors.white, // Texto blanco
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Bordes redondeados
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),

       // TextButton Theme (Para botones menos prominentes o links)
       textButtonTheme: TextButtonThemeData(
         style: TextButton.styleFrom(
           foregroundColor: AppColors.darkGreen, // Texto verde oscuro
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
         ),
       ),

      // InputDecoration Theme (Para TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // Rellenar el fondo
        fillColor: Colors.white, // Fondo blanco
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        border: OutlineInputBorder( // Borde por defecto
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none, // Sin borde visible por defecto
        ),
        enabledBorder: OutlineInputBorder( // Borde cuando está habilitado (sin foco)
           borderRadius: BorderRadius.circular(12.0),
           borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0), // Borde gris claro sutil
        ),
        focusedBorder: OutlineInputBorder( // Borde cuando tiene el foco
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5), // Borde verde principal
        ),
        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary), // Estilo del placeholder
        labelStyle: GoogleFonts.poppins(color: AppColors.darkGreen), // Estilo de la etiqueta flotante
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 1.0, // Sombra sutil
        color: AppColors.surface, // Fondo blanco
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
           side: BorderSide(color: Colors.grey.shade200, width: 0.5), // Borde muy sutil opcional
        ),
         margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0), // Margen por defecto
      ),

      // TabBar Theme
      tabBarTheme: TabBarTheme(
        indicator: BoxDecoration( // Estilo del indicador de pestaña seleccionada
          borderRadius: BorderRadius.circular(20),
          color: AppColors.primaryGreen,
        ),
        labelColor: Colors.white, // Texto de la pestaña seleccionada
        unselectedLabelColor: AppColors.darkGreen, // Texto de la no seleccionada
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Color(0xFF7d9b76), // Color de las líneas divisorias
        thickness: 1,
        space: 1, // Espacio que ocupa
      ),
    );
  }
}