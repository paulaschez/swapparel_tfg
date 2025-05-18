import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/app/config/routes/app_routes.dart';
import 'package:chat_app/features/auth/data/models/user_model.dart';
import 'package:chat_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:chat_app/features/garment/data/models/garment_model.dart';
import 'package:chat_app/features/profile/presentation/provider/profile_provider.dart';
import 'package:chat_app/features/profile/presentation/widgets/profile_garment_card.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/app/config/theme/app_theme.dart';
import 'package:chat_app/core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final String? viewingUserId; // ID del usuario cuyo perfil estemos viendo
  final bool isCurrentUserProfile;

  const ProfileScreen({
    super.key,
    this.viewingUserId,
    required this.isCurrentUserProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _targetUserId; // El ID del perfil que se va a cargar

  @override
  void initState() {
    super.initState();
    // Determinar el userId a cargar
    if (widget.isCurrentUserProfile) {
      // Si es el usuario logueado obtener su id
      final authProvider = Provider.of<AuthProviderC>(context, listen: false);
      _targetUserId = authProvider.currentUserId ?? '';
    } else {
      _targetUserId = widget.viewingUserId ?? '';
    }

    // Cargar datos del perfil
    if (_targetUserId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ProfileProvider>(
          context,
          listen: false,
        ).fetchUserProfileAndGarments(_targetUserId);
      });
    } else if (widget.isCurrentUserProfile) {
      print(
        "ProfileScreen WARN: Es Mi Perfil pero no se pudo obtener currentUserId.",
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el viewingUserId cambia sin pasar por MainAppScreen
    String newTargetUserId;
    if (widget.isCurrentUserProfile) {
      newTargetUserId =
          Provider.of<AuthProviderC>(context, listen: false).currentUserId ??
          '';
    } else {
      newTargetUserId = widget.viewingUserId ?? '';
    }

    if (newTargetUserId.isNotEmpty && newTargetUserId != _targetUserId) {
      _targetUserId = newTargetUserId;
      print(
        "ProfileScreen: viewingUserId cambió a $_targetUserId, recargando perfil.",
      );
      Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).fetchUserProfileAndGarments(_targetUserId, isRefresh: true);
    }
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Asegurarse que el widget aún está montado
        Provider.of<ProfileProvider>(context, listen: false).clearProfileData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProviderC>();
    final bool isMyProfile =
        widget.isCurrentUserProfile ||
        (authProvider.currentUserId != null &&
            authProvider.currentUserId ==
                profileProvider.viewedUserProfile?.id);

    // Tamaños y espaciados responsivos
    final double avatarRadius = ResponsiveUtils.avatarRadius(context);
    final double horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final double verticalSpacing = ResponsiveUtils.verticalSpacing(context);
    final double largeVerticalSpacing = ResponsiveUtils.largeVerticalSpacing(
      context,
    );
    final double gridPadding = ResponsiveUtils.gridPadding(context);

    // --- Datos del perfil ---
    final bool isLoading = profileProvider.isLoadingProfile;
    final String? errorMessage = profileProvider.profileErrorMessage;
    final UserModel? userProfile = profileProvider.viewedUserProfile;

    final String displayName =
        userProfile?.displayName ?? (userProfile?.name ?? "Usuario");
    final String username = userProfile?.name ?? "@usuario";
    final String photoUrl = userProfile?.photoUrl ?? '';

    // TODO: Obtener swapCount y ratingCount del userProfile o calcularlos
    const int swapCount = 0;
    const int ratingCount = 0;
    final List<GarmentModel> garmentsList = profileProvider.viewedUserGarments;

    final List<dynamic> garments = List.generate(
      5,
      (index) => {'name': 'Prenda Ejemplo Larga ${index + 1}'},
    );
    // --- Fin Datos de ejemplo ---

    return Scaffold(
      appBar: AppBar(
        leading:
            isMyProfile!
                ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    size: ResponsiveUtils.fontSize(
                      context,
                      baseSize: 20,
                      maxSize: 24,
                    ),
                  ),
                  onPressed: () => context.pop(),
                )
                : null,
        backgroundColor:
            isMyProfile
                ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).colorScheme.primary,
        title: Text(
          isMyProfile ? "Mi Perfil" : username,
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            color:
                isMyProfile
                    ? Theme.of(context).appBarTheme.foregroundColor
                    : Theme.of(context).colorScheme.onPrimary,
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
          if (isMyProfile)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color:
                    Theme.of(context).appBarTheme.actionsIconTheme?.color ??
                    AppColors.darkGreen,
                size: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 24,
                  maxSize: 28,
                ),
              ),
              onPressed: () {
                context.push(AppRoutes.editProfile);
              },
            ),
        ],
      ),
      body:
          isLoading && userProfile == null
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              )
              : errorMessage != null
              ? Center(
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Text(
                    "Error: $errorMessage",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              )
              : userProfile == null
              ? Center(
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Text(
                    "No se pudo cargar el perfil.",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalSpacing,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: verticalSpacing),
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            (photoUrl.isNotEmpty)
                                ? CachedNetworkImageProvider(photoUrl)
                                : null,
                        child:
                            photoUrl.isEmpty
                                ? Icon(
                                  Icons.person,
                                  size: avatarRadius * 0.9,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                      SizedBox(height: verticalSpacing * 1.2),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: ResponsiveUtils.fontSize(
                            context,
                            baseSize: 20,
                            tabletMultiplier: 1.2,
                            desktopMultiplier: 1.4,
                            maxSize: 30,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: verticalSpacing * 0.5),
                      Text(
                        username,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: ResponsiveUtils.fontSize(
                            context,
                            baseSize: 14,
                            tabletMultiplier: 1.1,
                            desktopMultiplier: 1.2,
                            maxSize: 18,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: largeVerticalSpacing),
                      const Divider(),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: verticalSpacing * 1.2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              context,
                              "Swaps",
                              swapCount.toString(),
                            ),
                            _buildStatColumn(
                              context,
                              "Valoraciones",
                              ratingCount.toString(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      SizedBox(height: largeVerticalSpacing),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: EdgeInsets.all(gridPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: verticalSpacing * 1.2,
                              ),
                              child: Text(
                                widget.isCurrentUserProfile
                                    ? "Mis Prendas"
                                    : "Prendas Disponibles",
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkGreen,
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    baseSize: 16,
                                    tabletMultiplier: 1.1,
                                    desktopMultiplier: 1.2,
                                    maxSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            _buildGarmentGrid(garments),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      floatingActionButton:
          widget.isCurrentUserProfile
              ? FloatingActionButton(
                onPressed: () => _showAddGarmentOptions(context),
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.fontSize(
              context,
              baseSize: 18,
              tabletMultiplier: 1.1,
              desktopMultiplier: 1.2,
              maxSize: 22,
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width * 0.01),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: ResponsiveUtils.fontSize(
              context,
              baseSize: 12,
              tabletMultiplier: 1.1,
              desktopMultiplier: 1.15,
              maxSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGarmentGrid(List<dynamic> garments) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // --- Puntos de ruptura para columnas ---

        final double availableWidth = constraints.maxWidth;

        // --- Puntos de ruptura para columnas ---
        final int crossAxisCount;
        if (availableWidth >= 550) {
          // Desktop grande
          crossAxisCount = 4;
        } else if (availableWidth >= 350) {
          // Tablet o desktop pequeño
          crossAxisCount = 3;
        } else {
          // Móvil
          crossAxisCount = 2;
        }

        // Espaciado entre elementos
        final double gridItemSpacing = availableWidth * 0.025;

        // Tamaño fijo del contenedor "polaroid"
        final double polaroidWidth =
            availableWidth < 600
                ? availableWidth * 0.4
                : 180; // Máximo 180px en pantallas grandes
        final double polaroidHeight =
            polaroidWidth * 1.3; // Relación de aspecto fija

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gridItemSpacing,
            mainAxisSpacing: gridItemSpacing,
            childAspectRatio:
                polaroidWidth /
                polaroidHeight, // Relación de aspecto basada en el tamaño fijo
          ),
          itemCount: garments.length,
          itemBuilder: (context, index) {
            final garment = garments[index];
            return ProfileGarmentCard(
              polaroidWidth: polaroidWidth,
              polaroidHeight: polaroidHeight,
              garment: garment,
            );
          },
        );
      },
    );
  }

  // --- Función para mostrar opciones al añadir prenda ---
  void _showAddGarmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Subir de la galería'),
                onTap: () {
                  // TODO: Implementar lógica para seleccionar de galería
                  print('Seleccionar de galería');
                  //Navigator.of(context).pop(); // Cierra el bottom sheet
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto'),
                onTap: () {
                  // TODO: Implementar lógica para tomar foto
                  print('Tomar foto');
                  //Navigator.of(context).pop(); // Cierra el bottom sheet
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
