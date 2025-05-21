// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/image_picker_utils.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:swapparel/features/auth/data/models/user_model.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:swapparel/features/profile/presentation/provider/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

// TODO: Arreglar que una vez cambiados los datos del usuario se vea
class _EditProfileScreenState extends State<EditProfileScreen> {
  late UserModel? _user;
  XFile? _pickedProfileImage;
  Uint8List? _pickedProfileImageBytes;

  // Controladores para los campos de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  // El correo no se edita, se muestra. La ubicación sí.
  final TextEditingController _locationController = TextEditingController();

  final _formKey = GlobalKey<FormState>(); // Para validación si la añades

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProviderC>(context, listen: false);
      if (authProvider.currentUserId != null) {
        _user = authProvider.currentUserModel;
        if (_user != null) {
          _nameController.text = _user!.name;
          _usernameController.text = _user!.username;
          _locationController.text = _user!.location ?? '';
        } else {
          print("error se ha no hay cargado un usuario en el modelo");
        }
      }
    });
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
          title: const Text(
            'Confirmar cierre de sesión',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          backgroundColor: AppColors.lightGreen,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false); // Cierra el dialogo y devuelve false
              },
              child: const Text('Cancelar'),
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

  Future<void> _handleImageSelection() async {
    final imageUtils = ImagePickerUtils();
    final XFile? image = await imageUtils.pickImage(context);

    if (image != null) {
      setState(() {
        _pickedProfileImage = image;
        if (kIsWeb) {
          image.readAsBytes().then((bytes) {
            if (mounted) {
              setState(() {
                _pickedProfileImageBytes = bytes;
              });
            }
          });
        }
        print("imagen seleccionada: ${image.path}");
      });
    } else {
      print("Selección de imagen cancelada o fallida");
    }
  }

  // Método helper para construir cada fila del formulario
  Widget _buildProfileDetailRow(
    BuildContext context,
    String label,
    TextEditingController controller,
    FormFieldValidator validator, {
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
              validator: validator,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 15,
                  maxSize: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = ResponsiveUtils.avatarRadius(context);
    final double verticalSpacing = ResponsiveUtils.verticalSpacing(context);
    final double largeVerticalSpacing = ResponsiveUtils.largeVerticalSpacing(
      context,
    );

    final authProvider = context.watch<AuthProviderC>();

    String placeholderPhotoUrl = authProvider.currentUserModel?.photoUrl ?? '';
    final String email =
        authProvider.currentUserModel?.email ?? "tucorreo@gmail.com";

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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final authP = Provider.of<AuthProviderC>(
                  context,
                  listen: false,
                );
                final profileP = Provider.of<ProfileProvider>(
                  context,
                  listen: false,
                );

                if (authP.currentUserId == null) {
                  return;
                }
                // TODO: Manejar el estado de carga aquí (ej: profileP.setIsUpdating(true))
                bool success = await profileP.updateUserProfile(
                  userId: authProvider.currentUserModel!.id,
                  name: _nameController.text,
                  username: _usernameController.text,
                  location: _locationController.text,
                  newProfileImage:
                      _pickedProfileImage != null
                          ? File(_pickedProfileImage!.path)
                          : null,
                );

                if (!mounted) return;
                if (success) {
                  await authP.reloadCurrentUserModel();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Perfil actualizado con éxito"),
                    ),
                  );
                  context
                      .pop(); // Ahora pop, después de que AuthProviderC (idealmente) tenga los datos frescos
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        profileP.profileErrorMessage ??
                            "Error al actualizar el perfil",
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }

              print(
                "Guardar cambios: Nombre: ${_nameController.text}, User: ${_usernameController.text}",
              );
              
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
                          kIsWeb && _pickedProfileImageBytes != null
                              ? MemoryImage(_pickedProfileImageBytes!)
                              : _pickedProfileImage != null
                              ? FileImage(File(_pickedProfileImage!.path))
                              : (placeholderPhotoUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                    placeholderPhotoUrl,
                                  )
                                  : null),
                      child:
                          (_pickedProfileImage == null &&
                                  placeholderPhotoUrl.isEmpty)
                              ? Icon(
                                Icons.person,
                                size: avatarRadius * 0.9,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    TextButton(
                      onPressed: () async {
                        _handleImageSelection();
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
                    _buildProfileDetailRow(
                      context,
                      "Nombre:",
                      _nameController,
                      (value) {
                        if (value == null || value.isEmpty) {
                          return 'Debe introducir un nombre.';
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 1),
                    _buildProfileDetailRow(
                      context,
                      "Nombre de usuario:",
                      _usernameController,
                      (value) {
                        if (value == null || value.isEmpty) {
                          return 'Debe introducir el nombre de usuario';
                        }
                        return null;
                      },
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
                      (value) => null,
                    ),
                    SizedBox(height: largeVerticalSpacing * 1.5),
                    // --- BOTÓN CERRAR SESIÓN ---
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
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
