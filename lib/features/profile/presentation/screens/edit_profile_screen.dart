// ignore_for_file: avoid_print

import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// TODO: Importar AuthProviderC para el logout y ProfileProvider para cargar/guardar datos
// import 'package:provider/provider.dart';
// import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
// import 'package:swapparel/features/profile/presentation/provider/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controladores para los campos de texto
  // TODO: Inicializarlos con los datos actuales del usuario desde el ProfileProvider en initState
  final TextEditingController _nameController = TextEditingController(
    text: "Nombre Placeholder",
  );
  final TextEditingController _usernameController = TextEditingController(
    text: "@username_placeholder",
  );
  // El correo no se edita, se muestra. La ubicación sí.
  final TextEditingController _locationController = TextEditingController(
    text: "Ubicación Placeholder",
  );

  final _formKey = GlobalKey<FormState>(); // Para validación si la añades

  @override
  void initState() {
    super.initState();
    // TODO: Cargar datos del perfil actual en los controllers
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    //   final authProvider = Provider.of<AuthProviderC>(context, listen: false);
    //   if (authProvider.currentUserId != null) {
    //     // Asumiendo que ProfileProvider tiene un método para obtener el UserModel actual
    //     // o que ya lo tiene cargado.
    //     final user = profileProvider.currentUserProfileData; // Necesitarías este getter
    //     if (user != null) {
    //       _nameController.text = user.name ?? '';
    //       _usernameController.text = user.usernameFromEmailIfNotSet; // Un getter en UserModel
    //       _locationController.text = user.location ?? '';
    //     } else {
    //        // Quizás llamar a un método para cargar el perfil si no está
    //        // profileProvider.fetchProfile(authProvider.currentUserId!);
    //     }
    //   }
    // });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool? didConfirm = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar cierre de sesión', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          backgroundColor: AppColors.lightGreen,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false); // Cierra el dialogo y devuelve false
              },
              child: const Text('Cancelar',),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true); // Cierra el dialogo y devuelve true
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceEvenly,
        );
      },
    );

    // Si el usuario confirmo
    if (didConfirm == true) {
      final authProvider = Provider.of<AuthProviderC>(context, listen: false);
      await authProvider.signOut();
      print("Usuario cerró sesión y debería ser redirigido por GoRouter.");
    }
  }

  // Método helper para construir cada fila del formulario
  Widget _buildProfileDetailRow(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.verticalSpacing(context) * 0.75,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2, // Dar más espacio a la etiqueta
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 15,
                  maxSize: 17,
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.horizontalPadding(context) * 0.5),
          Expanded(
            flex: 4, // Dar más espacio al campo de texto
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 15,
                  maxSize: 17,
                ),
              ),

              // TODO: Añadir validadores 
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = ResponsiveUtils.avatarRadius(context) ;
    final double verticalSpacing = ResponsiveUtils.verticalSpacing(context);
    final double largeVerticalSpacing = ResponsiveUtils.largeVerticalSpacing(
      context,
    );

    // TODO: Obtener datos reales del ProfileProvider
    // const String placeholderPhotoUrl = profileProvider.currentUserProfileData?.photoUrl ?? '';
    // final String email = authProvider.currentUser?.email ?? "tucorreo@gmail.com";
    // --- Datos de ejemplo ---

    const String placeholderPhotoUrl = '';
    const String email = "tucorreo@gmail.com";

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: ResponsiveUtils.fontSize(context, baseSize: 20, maxSize: 24),
          ),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "Editar perfil",
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: ResponsiveUtils.fontSize(
              context,
              baseSize: 18,
              tabletMultiplier: 1.1,
              desktopMultiplier: 1.2,
              maxSize: 22,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Validar formulario: if (_formKey.currentState!.validate()) { ... }
              // TODO: Llamar a profileProvider.updateUserProfile(
              //   name: _nameController.text,
              //   username: _usernameController.text,
              //   location: _locationController.text,
              //   // y la nueva photoUrl si se cambió
              // );
              print(
                "Guardar cambios: Nombre: ${_nameController.text}, User: ${_usernameController.text}",
              );
              context.pop(); // Vuelve a la pantalla anterior después de guardar
            },
            child: Text(
              "Guardar",
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: ResponsiveUtils.fontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.all(
                ResponsiveUtils.largeVerticalSpacing(context) * 1.5,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: verticalSpacing),
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          placeholderPhotoUrl.isNotEmpty
                              ? NetworkImage(
                                placeholderPhotoUrl,
                              ) // TODO: Usar CachedNetworkImage
                              : null,
                      child:
                          placeholderPhotoUrl.isEmpty
                              ? Icon(
                                Icons.person,
                                size: avatarRadius * 0.9,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Implementar _showImageSourceActionSheet (cámara/galería)
                        print("Editar foto presionado");
                      },
                      child: Text(
                        "Cambiar foto",
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: ResponsiveUtils.fontSize(
                            context,
                            baseSize: 15,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: largeVerticalSpacing),
                    const Divider(),
                    SizedBox(height: verticalSpacing * 1.2),
                    _buildProfileDetailRow(context, "Nombre:", _nameController),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      context,
                      "Nombre de usuario:",
                      _usernameController,
                    ),
                    const Divider(height: 1),
                    // Correo (no editable)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical:
                            ResponsiveUtils.verticalSpacing(context) * 0.75,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Correo:",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: ResponsiveUtils.fontSize(
                                  context,
                                  baseSize: 15,
                                  maxSize: 17,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width:
                                ResponsiveUtils.horizontalPadding(context) *
                                0.5,
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              email, // Mostrar el email actual
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(
                                  context,
                                  baseSize: 15,
                                  maxSize: 17,
                                ),
                                overflow: TextOverflow.clip,
                                color:
                                    Colors
                                        .grey[600], // Indicar que no es editable
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      context,
                      "Ubicación:",
                      _locationController,
                    ),
                    SizedBox(height: largeVerticalSpacing * 1.5),
                    // --- BOTÓN CERRAR SESIÓN ---
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          // TODO: Mostrar diálogo de confirmación
                          _confirmSignOut(context);
                          print("Cerrar Sesión presionado");
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.likeRed.withValues(
                            alpha: 0.1,
                          ), // Un fondo rojo muy sutil
                          padding: EdgeInsets.symmetric(
                            vertical: verticalSpacing * 0.9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Cerrar Sesión",
                          style: TextStyle(
                            color:
                                AppColors
                                    .likeRed, // Rojo para indicar acción de "salida"
                            fontSize: ResponsiveUtils.fontSize(
                              context,
                              baseSize: 16,
                              maxSize: 18,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: largeVerticalSpacing),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
