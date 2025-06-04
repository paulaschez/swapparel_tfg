import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swapparel/core/utils/dialog_utils.dart';
import 'package:swapparel/features/profile/presentation/provider/profile_provider.dart';
import '../../../../app/config/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/models/garment_model.dart';
import '../provider/garment_detail_provider.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import 'package:go_router/go_router.dart';

class GarmentDetailScreen extends StatefulWidget {
  final String
  garmentId; // Todavía necesario para el constructor, pero no se usará para fetch

  const GarmentDetailScreen({super.key, required this.garmentId});

  @override
  State<GarmentDetailScreen> createState() => _GarmentDetailScreenState();
}

class _GarmentDetailScreenState extends State<GarmentDetailScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar los detalles de la prenda al iniciar la pantalla
      Provider.of<GarmentDetailProvider>(
        context,
        listen: false,
      ).fetchGarmentDetails(widget.garmentId);
    });
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.fontSize(context, baseSize: 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveUtils.fontSize(
                context,
                baseSize: 15,
                maxSize: 17,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

  Widget _buildDotIndicator(int index) {
    bool isActive = _currentImageIndex == index;
    return GestureDetector(
      onTap: () {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5.0),
        height: isActive ? 9.0 : 8.0,
        width: isActive ? 9.0 : 8.0,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.fontSize(
            context,
            baseSize: 18,
            maxSize: 22,
          ), // Más padding horizontal
          vertical: ResponsiveUtils.fontSize(context, baseSize: 8, maxSize: 10),
        ),
        decoration: BoxDecoration(
          color: Color(0xFFb0c1b5),
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: AppColors.primaryGreen),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 14,
                  maxSize: 16,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppColors.darkGreen,
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 14,
                  maxSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    AuthProviderC auhtProvider,
  ) async {
    final bool? confirmDelete = await showConfirmationDialogFixed(
      context: context,
      title: 'Eliminar Prenda',
      content:
          '¿Estás seguro de que quieres eliminar esta prenda? Esta acción no se puede deshacer.',
      confirmButtonText: 'Eliminar',
      isDestructiveAction: true,
    );

    // Si el usuario confirmo
    if (confirmDelete == true) {
      final garmentDetailProvider = Provider.of<GarmentDetailProvider>(
        context,
        listen: false,
      );
      final success = await garmentDetailProvider.deleteThisGarment();
      if (success && mounted) {
        Provider.of<ProfileProvider>(
          context,
          listen: false,
        ).refreshUserGarments(auhtProvider.currentUserId!);
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Prenda eliminada.")));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al eliminar la prenda."), backgroundColor: AppColors.error,),
          );
        }
      }
    }
  }

  late final PageController _pageController;

  @override
  Widget build(BuildContext context) {
    final garmentDetailProvider = context.watch<GarmentDetailProvider>();
    final authProvider = context.watch<AuthProviderC>();

    final GarmentModel? garment = garmentDetailProvider.garment;
    final bool isLoading = garmentDetailProvider.isLoading;
    final String? errorMessage = garmentDetailProvider.errorMessage;

    final bool isMyGarment =
        garment != null && authProvider.currentUserId == garment.ownerId;
    final bool isLiked = garmentDetailProvider.isLikedByCurrentUser;

    const String editOption = 'edit';
    const String deleteOption = 'delete';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: ResponsiveUtils.fontSize(context, baseSize: 20),
          ),
          onPressed: () => context.pop(),
        ),

        actions: [
          if (isMyGarment)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).appBarTheme.actionsIconTheme?.color,
              ),
              onSelected: (String result) {
                // Lógica para manejar la selección del menú
                if (result == editOption) {
                  print("Simulación: Editar prenda ${garment.id}");
                  context.pushNamed(
                    'editGarment',
                    pathParameters: {'garmentId': garment.id},
                  );
                } else if (result == deleteOption) {
                  print(
                    "Simulación: Mostrar diálogo para borrar prenda ${garment.id}",
                  );

                  _handleDelete(context, authProvider);
                }
              },
              borderRadius: BorderRadius.circular(20),
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: editOption,
                      child: ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Editar'),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: deleteOption,
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          'Borrar',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body:
          isLoading && garment == null
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Error de ejemplo: $errorMessage",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              )
              : garment == null
              ? const Center(child: Text("Prenda no encontrada (ejemplo)."))
              : SingleChildScrollView(
                padding: EdgeInsets.all(
                  ResponsiveUtils.horizontalPadding(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: 1 / 1.1,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primaryGreen,
                                width: 1.5,
                              ),
                            ),
                            child: PageView.builder(
                              itemCount: garment.imageUrls.length,
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return CachedNetworkImage(
                                  imageUrl: garment.imageUrls[index],
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => const Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.grey,
                                        size: 30,
                                      ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Botón de Like
                        if (!isMyGarment)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    isLiked ? AppColors.likeRed : Colors.white,
                                size: 28,
                              ),
                              onPressed: () async {
                                await garmentDetailProvider
                                    .toggleLikeOnGarment();
                              },
                            ),
                          ),
                        if (garment.imageUrls.length > 1 && kIsWeb) ...[
                          if (_currentImageIndex != 0)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  if (_pageController.hasClients) {
                                    _pageController.animateToPage(
                                      _currentImageIndex - 1,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                              ),
                            ),

                          if (_currentImageIndex !=
                              garment.imageUrls.length - 1)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  if (_pageController.hasClients) {
                                    _pageController.animateToPage(
                                      _currentImageIndex + 1,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                              ),
                            ),
                        ],

                        // Puntos de navegación
                        if (garment.imageUrls.length > 1)
                          Positioned(
                            bottom: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  garment.imageUrls.length,
                                  (index) => _buildDotIndicator(index),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(
                      height: ResponsiveUtils.largeVerticalSpacing(context),
                    ),

                    Text(
                      garment.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: ResponsiveUtils.verticalSpacing(context)),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildChip("Talla", garment.size),
                        SizedBox(
                          width:
                              ResponsiveUtils.horizontalPadding(context) * 0.5,
                        ),
                        _buildChip("Condición", garment.condition),
                      ],
                    ),

                    SizedBox(
                      height: ResponsiveUtils.largeVerticalSpacing(context),
                    ),

                    if (garment.description != null &&
                        garment.description!.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Descripción",
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(
                              context,
                              baseSize: 16,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveUtils.verticalSpacing(context) * 0.4,
                      ),
                      Text(
                        garment.description!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: ResponsiveUtils.fontSize(
                            context,
                            baseSize: 15,
                            maxSize: 17,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(
                      height: ResponsiveUtils.largeVerticalSpacing(context),
                    ),

                    if (garment.brand != null ||
                        garment.category != null ||
                        garment.color != null ||
                        garment.material != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Otros detalles:",
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(
                              context,
                              baseSize: 16,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (garment.brand != null && garment.brand!.isNotEmpty)
                        _buildDetailRow(context, "Marca", garment.brand),
                      if (garment.category != null &&
                          garment.category!.isNotEmpty)
                        _buildDetailRow(context, "Categoría", garment.category),
                      if (garment.color != null && garment.color!.isNotEmpty)
                        _buildDetailRow(context, "Color", garment.color),
                      if (garment.material != null &&
                          garment.material!.isNotEmpty)
                        _buildDetailRow(context, "Material", garment.material),
                    ],

                    SizedBox(
                      height: ResponsiveUtils.verticalSpacing(context) * 0.5,
                    ),

                    SizedBox(
                      height: ResponsiveUtils.largeVerticalSpacing(context),
                    ),

                    if (!isMyGarment) ...[
                      Divider(color: AppColors.primaryGreen),
                      SizedBox(
                        height: ResponsiveUtils.verticalSpacing(context),
                      ),
                      GestureDetector(
                        onTap:
                            () => context.pushNamed(
                              'profile',
                              pathParameters: {'userId': garment.ownerId},
                            ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius:
                                  ResponsiveUtils.avatarRadius(context) * 0.5,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  (garment.ownerPhotoUrl != null &&
                                          garment.ownerPhotoUrl!.isNotEmpty)
                                      ? CachedNetworkImageProvider(
                                        garment.ownerPhotoUrl!,
                                      )
                                      : null,
                              onBackgroundImageError:
                                  (garment.ownerPhotoUrl != null &&
                                          garment.ownerPhotoUrl!.isNotEmpty)
                                      ? (exception, stackTrace) {
                                        print(
                                          "Error cargando CachedNetworkImageProvider: $exception",
                                        );
                                      }
                                      : null,
                              child:
                                 (garment.ownerPhotoUrl == null || garment.ownerPhotoUrl!.isEmpty) 
                                      ? Icon(
                                        Icons.person,
                                        size:
                                            ResponsiveUtils.avatarRadius(
                                              context,
                                            ) *
                                            0.5,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                            SizedBox(
                              width: ResponsiveUtils.verticalSpacing(context),
                            ),
                            Text(
                              "@${garment.ownerUsername}",
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(
                                  context,
                                  baseSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(
                      height: ResponsiveUtils.largeVerticalSpacing(context) * 2,
                    ),
                  ],
                ),
              ),
    );
  }
}
