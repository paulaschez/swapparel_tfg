import 'package:flutter/material.dart';
import 'package:chat_app/app/config/theme/app_theme.dart';
import 'package:chat_app/core/utils/responsive_utils.dart'; 


// TODO: Importar modelos y Provider

class ProfileScreen extends StatelessWidget {
  final String userId;
  final bool isCurrentUserProfile;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.isCurrentUserProfile,
  });

  
  @override
  Widget build(BuildContext context) {
   

    // Tamaños y espaciados responsivos
    final double avatarRadius = ResponsiveUtils.avatarRadius(context);
    final double horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final double verticalSpacing = ResponsiveUtils.verticalSpacing(context);
    final double largeVerticalSpacing = ResponsiveUtils.largeVerticalSpacing(context);
    final double gridPadding = ResponsiveUtils.gridPadding(context);

    // --- Datos de ejemplo ---
    const bool isLoading = false;
    const String? errorMessage = null;
    const String placeholderUsername = "@username_placeholder";
    const String placeholderName = "Nombre Completo Placeholder";
    const String placeholderPhotoUrl = '';
    const int swapCount = 0;
    const int ratingCount = 0;
    final List<dynamic> garments = List.generate(
      5,
      (index) => {'name': 'Prenda Ejemplo Larga ${index + 1}'},
    );
    // --- Fin Datos de ejemplo ---

    return Scaffold(
      appBar: AppBar(
        leading:
            !isCurrentUserProfile
                ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    size: ResponsiveUtils.fontSize(
                      context,
                      baseSize: 20,
                      maxSize: 24,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
        backgroundColor:
            isCurrentUserProfile
                ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).colorScheme.primary,
        title: Text(
          isCurrentUserProfile ? "Mi Perfil" : placeholderUsername,
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            color:
                isCurrentUserProfile
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
          if (isCurrentUserProfile)
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
                /* ... */
              },
            ),
        ],
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                    children: <Widget>[
                      SizedBox(height: verticalSpacing),
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.grey[300],
                        child:
                            placeholderPhotoUrl.isEmpty
                                ? Icon(
                                  Icons.person,
                                  size: avatarRadius * 0.9,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                      SizedBox(height: verticalSpacing * 1.2),
                      Text(
                        placeholderName,
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
                        placeholderUsername,
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
                          color: AppColors.lightGreen.withOpacity(0.4),
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
                                isCurrentUserProfile
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
          isCurrentUserProfile
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

  Widget _buildGarmentGrid(
   
    List<dynamic> garments,
   
  ) {
    return LayoutBuilder(builder: (context, constraints) {
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
      final double polaroidWidth = availableWidth < 600 ? availableWidth * 0.4 : 180; // Máximo 180px en pantallas grandes
      final double polaroidHeight = polaroidWidth * 1.3; // Relación de aspecto fija

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
        return Container(
          padding: EdgeInsets.all(8),
          width: polaroidWidth, // Ancho fijo
          height: polaroidHeight, // Alto fijo
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1 / 1, // Imagen cuadrada
                child: Container(
                  color: Colors.white, // Placeholder
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 30,
                    ),
                  ),
                  // TODO: Usar Image.network(garment.imageUrl, fit: BoxFit.cover)
                ),
              ),

              // Nombre de la prenda
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        garment['name'],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.darkGreen,
                          fontSize: ResponsiveUtils.fontSize(
                            context,
                            baseSize: 10,
                            tabletMultiplier: 1.05,
                            desktopMultiplier: 1.1,
                            maxSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    }
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
                  Navigator.of(context).pop(); // Cierra el bottom sheet
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto'),
                onTap: () {
                  // TODO: Implementar lógica para tomar foto
                  print('Tomar foto');
                  Navigator.of(context).pop(); // Cierra el bottom sheet
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
