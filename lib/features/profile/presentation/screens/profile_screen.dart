import 'package:cached_network_image/cached_network_image.dart';
import 'package:swapparel/app/config/routes/app_routes.dart';
import 'package:swapparel/features/auth/data/models/user_model.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/garment/data/models/garment_model.dart';
import 'package:swapparel/features/profile/presentation/provider/profile_provider.dart';
import 'package:swapparel/features/profile/presentation/widgets/profile_garment_card.dart';
import 'package:flutter/material.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
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
    _initProfileData();
  }

  void _initProfileData() {
    // Determinar el userId a cargar
    final authProvider = Provider.of<AuthProviderC>(context, listen: false);
    if (widget.isCurrentUserProfile) {
      _targetUserId = authProvider.currentUserId ?? '';
      if (_targetUserId.isEmpty) {
        print(
          "ProfileScreen WARN (initState/didUpdate): Es Mi Perfil pero currentUserId es nulo/vacío. No se iniciará la carga aún.",
        );
      }
    } else {
      _targetUserId = widget.viewingUserId ?? '';
      if (_targetUserId.isEmpty) {
        print(
          "ProfileScreen ERROR (initState/didUpdate): Se está viendo el perfil de otro usuario pero viewingUserId es nulo/vacío.",
        );
        Provider.of<ProfileProvider>(context, listen: false).clearProfileData();
      }
    }

    if (_targetUserId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<ProfileProvider>(
            context,
            listen: false,
          ).fetchUserProfileAndGarments(_targetUserId);
        }
      });
    } else {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<ProfileProvider>(
            context,
            listen: false,
          ).clearProfileData();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final authProvider = Provider.of<AuthProviderC>(context, listen: false);
    String newPotentialTargetUserId;

    if (widget.isCurrentUserProfile) {
      newPotentialTargetUserId = authProvider.currentUserId ?? '';
    } else {
      newPotentialTargetUserId = widget.viewingUserId ?? '';
    }

    if (newPotentialTargetUserId != _targetUserId ||
        widget.isCurrentUserProfile != oldWidget.isCurrentUserProfile) {
      print(
        "ProfileScreen: widget updated. Old target: $_targetUserId, New potential: $newPotentialTargetUserId. isCurrentUserProfile changed: ${widget.isCurrentUserProfile != oldWidget.isCurrentUserProfile}. Recargando perfil.",
      );

      _initProfileData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ProfileProvider>(context, listen: false).clearProfileData();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProviderC>();

    if (widget.isCurrentUserProfile && _targetUserId.isEmpty) {
      print(
        "ProfileScreen Build: _targetUserId is empty for current user profile. Showing waiting state.",
      );
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mi Perfil"),
          backgroundColor: AppColors.background,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Esperando datos de usuario..."),
            ],
          ),
        ),
      );
    }
    // Si _targetUserId está vacío para el perfil de otro usuario, es un error de programación o de ruta.
    if (!widget.isCurrentUserProfile && _targetUserId.isEmpty) {
      print(
        "ProfileScreen Build: _targetUserId is empty for other user profile. Showing error state.",
      );
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Error de Perfil",
            style: TextStyle(color: AppColors.darkGreen),
          ),
          backgroundColor: AppColors.background,
        ),
        body: const Center(
          child: Text("No se pudo determinar el usuario a visualizar."),
        ),
      );
    }

    final bool isMyProfile =
        widget.isCurrentUserProfile ||
        (authProvider.currentUserId != null &&
            authProvider.currentUserId ==
                profileProvider.viewedUserProfile?.id);

    if (profileProvider.isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            isMyProfile ? "Mi Perfil" : "Cargando...",
            style: TextStyle(color: AppColors.darkGreen),
          ),
          backgroundColor: AppColors.background,
        ), // Título provisional
        body: const Center(child: CircularProgressIndicator()),
      );
    }


    if (profileProvider.viewedUserProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            isMyProfile ? "Mi Perfil" : "Error",
            style: TextStyle(color: AppColors.darkGreen),
          ),
          backgroundColor: AppColors.background,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              profileProvider.profileErrorMessage ??
                  'No se pudo cargar el perfil.',
            ),
          ),
        ),
      );
    }
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
    final UserModel userProfile =
        profileProvider.viewedUserProfile!; // ¡Ahora es seguro!

    final String name = userProfile.name;
    final String username = userProfile.username;
    final String photoUrl = userProfile.photoUrl ?? '';

    final int swapCount = userProfile.swapCount;
    final int ratingCount = userProfile.numberOfRatings;
    final double averageRating = userProfile.averageRating;

    final List<GarmentModel> garments = profileProvider.viewedUserGarments;

    return Scaffold(
      appBar: AppBar(
        leading:
            !isMyProfile
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
          isLoading
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
                        onBackgroundImageError:
                            photoUrl.isNotEmpty
                                ? (exception, stackTrace) {
                                  print(
                                    "Error cargando CachedNetworkImageProvider: $exception",
                                  );
                                }
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
                        name,
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

                      // --- MOSTRAR ESTRELLAS DE VALORACIÓN ---
                      if (ratingCount > 0) // Solo mostrar si hay valoraciones
                        Padding(
                          padding: EdgeInsets.only(bottom: verticalSpacing),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: ResponsiveUtils.fontSize(
                                  context,
                                  baseSize: 20,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                averageRating.toStringAsFixed(
                                  1,
                                ), // Mostrar con 1 decimal
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    baseSize: 16,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "($ratingCount ${ratingCount == 1 ? 'valoración' : 'valoraciones'})",
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    baseSize: 14,
                                  ),
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (ratingCount == 0)
                        Padding(
                          padding: EdgeInsets.only(bottom: verticalSpacing),
                          child: Text(
                            "Sin valoraciones aún",
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(
                                context,
                                baseSize: 14,
                              ),
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

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
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: 220),
                        child: Container(
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
                              garments.isNotEmpty
                                  ? _buildGarmentGrid(garments)
                                  : ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: 120),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "No hay prendas subidas aún. ",
                                                  style: TextStyle(
                                                    fontSize:
                                                        ResponsiveUtils.fontSize(
                                                          context,
                                                          baseSize: 18,
                                                        ),
                                                    color:
                                                        AppColors.primaryGreen,
                                                  ),
                                                ),

                                                Text(
                                                  isMyProfile
                                                      ? "¡Sube alguna!"
                                                      : '',
                                                  style: TextStyle(
                                                    fontSize:
                                                        ResponsiveUtils.fontSize(
                                                          context,
                                                          baseSize: 18,
                                                        ),
                                                    color:
                                                        AppColors.primaryGreen,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      floatingActionButton:
          widget.isCurrentUserProfile
              ? FloatingActionButton(
                heroTag: "profileScreenFAB",
                onPressed: () => context.push(AppRoutes.addGarment),
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

        final double polaroidWidth =
            availableWidth < 600 ? availableWidth * 0.4 : 180;
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
            return GestureDetector(
              onTap: () {
                print("Navegando a detalle de prenda ID: ${garment.id}");
                context.pushNamed(
                  'garmentDetail',
                  pathParameters: {'garmentId': garment.id},
                );
              },
              child: ProfileGarmentCard(garment: garment),
            );
          },
        );
      },
    );
  }
}
