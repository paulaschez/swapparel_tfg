import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/dialog_utils.dart';
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

class _EditProfileScreenState extends State<EditProfileScreen> {
  XFile? _pickedProfileImage;
  Uint8List? _pickedProfileImageBytes;
  bool _removingCurrentImage = false;

  // Controladores para los campos de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isSavingProfile = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    print("EditProfileScreen: initState CALLED");
  }

  void _initializeControllers(UserModel user) {
    print(
      "EditProfileScreen: _initializeControllers CALLED for user: ${user.name}",
    );
    _nameController.text = user.name;
    _usernameController.text = user.username;
    _locationController.text = user.location ?? '';
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    print("EditProfileScreen: dispose CALLED");

    _nameController.dispose();
    _usernameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final bool? didConfirm = await showConfirmationDialogFixed(
      context: context,
      title: 'Cerrar Sesión',
      content: '¿Estás seguro de que quieres cerrar la sesión actual?',
      confirmButtonText: 'Cerrar Sesión',
      isDestructiveAction: true,
    );

    if (didConfirm == true) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProviderC>(context, listen: false);
      print("Usuario cerró sesión y debería ser redirigido por GoRouter.");
      await authProvider.signOut();
    } else {
      print("Cierre de sesión cancelado por el usuario.");
    }
  }

  Future<void> _handleImageSelection() async {
    final imageUtils = ImagePickerUtils();
    final XFile? image = await imageUtils.pickImage(context);

    if (image != null) {
      setState(() {
        _pickedProfileImage = image;
        _removingCurrentImage = false;
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

  void _handleRemoveImage() {
    setState(() {
      _pickedProfileImage = null;
      _pickedProfileImageBytes = null;
      _removingCurrentImage = true;
    });
    print("Marcado para eliminar la foto de perfil.");
  }

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
            flex: 2,
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
            flex: 4,
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
    final UserModel? currentUserFromProvider = authProvider.currentUserModel;
    print(
      "EditProfileScreen build: authProvider.currentUserId = ${authProvider.currentUserId}",
    );
    print(
      "EditProfileScreen build: currentUserFromProvider is ${currentUserFromProvider == null ? 'NULL' : 'NOT NULL (Name: ${currentUserFromProvider.name})'}",
    );

    // --- ESTADO DE CARGA ---
    if (authProvider.currentUserId == null) {
      print(
        "EditProfileScreen build: currentUserId is NULL. Showing 'Not Authenticated'.",
      );
      return Scaffold(
        appBar: AppBar(title: const Text("Editar Perfil")),
        body: const Center(child: Text("Usuario no autenticado.")),
      );
    }

    if (currentUserFromProvider == null) {
      print(
        "EditProfileScreen build: currentUserFromProvider is NULL (but userId exists). Showing CircularProgressIndicator.",
      );
      return Scaffold(
        appBar: AppBar(title: const Text("Editar Perfil")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_controllersInitialized) {
      _initializeControllers(currentUserFromProvider);
    }

    String currentPhotoUrlForDisplay = currentUserFromProvider.photoUrl ?? '';
    final String email = currentUserFromProvider.email;

    print(
      "EditProfileScreen build: currentPhotoUrlForDisplay = $currentPhotoUrlForDisplay",
    );
    print(
      "EditProfileScreen build: _removingCurrentImage = $_removingCurrentImage",
    );
    print(
      "EditProfileScreen build: _pickedProfileImage is ${_pickedProfileImage == null ? 'NULL' : 'NOT NULL'}",
    );

    bool hasVisiblePhoto =
        (_pickedProfileImage != null) ||
        (currentPhotoUrlForDisplay.isNotEmpty && !_removingCurrentImage);
    print("EditProfileScreen build: hasVisiblePhoto = $hasVisiblePhoto");

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
            onPressed:
                _isSavingProfile
                    ? null
                    : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isSavingProfile = true;
                        });

                        final authP = Provider.of<AuthProviderC>(
                          context,
                          listen: false,
                        );
                        final profileP = Provider.of<ProfileProvider>(
                          context,
                          listen: false,
                        );

                        if (authP.currentUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Error: Usuario no encontrado."),
                               backgroundColor: AppColors.error,
                            ),
                          );
                          setState(() {
                            _isSavingProfile = false;
                          });
                          return;
                        }

                        String? photoUrlForDeletion;
                        if ((_pickedProfileImage != null ||
                                _removingCurrentImage) &&
                            currentUserFromProvider.photoUrl != null &&
                            currentUserFromProvider.photoUrl!.isNotEmpty) {
                          photoUrlForDeletion =
                              currentUserFromProvider.photoUrl;
                        }

                        bool success = await profileP.updateUserProfile(
                          userId: authP.currentUserModel!.id,
                          name: _nameController.text,
                          username: _usernameController.text,
                          location: _locationController.text,
                          newProfileImage: _pickedProfileImage,
                          currentUsername: authP.currentUserModel!.username,
                          removeCurrentPhoto: _removingCurrentImage,
                          previousPhotoUrl: photoUrlForDeletion,
                        );

                        if (!mounted) return;

                        if (success) {
                          await authP.reloadCurrentUserModel();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Perfil actualizado con éxito"),
                               backgroundColor: AppColors.primaryGreen,
                            ),
                          );

                          context.pop();

                          setState(() {
                            _isSavingProfile = false;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                profileP.profileErrorMessage ??
                                    "Error al actualizar el perfil",
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }

                      print(
                        "Guardar cambios: Nombre: ${_nameController.text}, User: ${_usernameController.text}",
                      );
                    },
            child:
                _isSavingProfile
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryGreen, // O el color del texto
                      ),
                    )
                    : Text(
                      "Guardar",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: ResponsiveUtils.fontSize(
                          context,
                          baseSize: 18,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
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
                            _removingCurrentImage
                                ? null
                                : kIsWeb && _pickedProfileImageBytes != null
                                ? MemoryImage(_pickedProfileImageBytes!)
                                : _pickedProfileImage != null
                                ? FileImage(File(_pickedProfileImage!.path))
                                : (currentPhotoUrlForDisplay.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                      currentPhotoUrlForDisplay,
                                    )
                                    : null),
                        child:
                            (_pickedProfileImage ==
                                        null && // No hay imagen local seleccionada Y
                                    (currentPhotoUrlForDisplay.isEmpty ||
                                        _removingCurrentImage)) // (no hay URL de red O se está eliminando la actual)
                                ? Icon(
                                  Icons.person,
                                  size: avatarRadius * 0.9,
                                  color:
                                      Colors
                                          .white, 
                                )
                                : null, // No mostrar child si hay una imagen local o una de red (y no se está eliminando)
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
                      if (hasVisiblePhoto) // Mostrar solo si hay una foto que se pueda eliminar
                        TextButton(
                          onPressed: _handleRemoveImage,
                          child: Text(
                            "Eliminar foto de perfil",
                            style: TextStyle(
                              color:
                                  AppColors
                                      .likeRed, // Usar un color distintivo para eliminar
                              fontSize: ResponsiveUtils.fontSize(
                                context,
                                baseSize: 14,
                              ),
                              fontWeight: FontWeight.w500,
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
                            _handleSignOut(context);
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
      ),
    );
  }
}
