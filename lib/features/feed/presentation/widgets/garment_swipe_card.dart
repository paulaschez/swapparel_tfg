import 'package:flutter/material.dart';
//import 'package:cached_network_image/cached_network_image.dart';
import '../../../garment/data/models/garment_model.dart';
import '../../../../app/config/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart'; 

class GarmentSwipeCard extends StatefulWidget {
  final GarmentModel garment;
  final VoidCallback? onInfoTap;
  final VoidCallback? onProfileTap;

  const GarmentSwipeCard({
    super.key,
    required this.garment,
    this.onInfoTap,
    this.onProfileTap,
  });

  @override
  State<GarmentSwipeCard> createState() => _GarmentSwipeCardState();
}

class _GarmentSwipeCardState extends State<GarmentSwipeCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
       
        final double aspectRatio = 2 / 3;

        return Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                //borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreen.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            //borderRadius: BorderRadius.circular(15.0),
                            color: Colors.grey[200],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              widget.garment.imageUrls.isNotEmpty
                                  // --- SIMULACIÓN DE IMAGEN DE RED ---
                                  ? Container(
                                    // Placeholder visual para la imagen
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      image:
                                          _currentImageIndex < 2
                                              ? DecorationImage(
                                                // Simula 2 imágenes diferentes
                                                image: NetworkImage(
                                                  "https://picsum.photos/seed/${widget.garment.id}_$_currentImageIndex/400/600",
                                                ), // Imagen placeholder aleatoria
                                                fit: BoxFit.cover,
                                              )
                                              : null,
                                      color:
                                          _currentImageIndex >= 2
                                              ? Colors.blueGrey
                                              : null, // Color si no hay imagen
                                    ),
                                    child: Text(
                                      "Imagen ${widget.garment.imageUrls[_currentImageIndex]}",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  )
                                  // : CachedNetworkImage(
                                  //     imageUrl: widget.garment.imageUrls[_currentImageIndex],
                                  //     fit: BoxFit.cover,
                                  //     width: double.infinity,
                                  //     height: double.infinity,
                                  //     placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  //     errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  //   )
                                  : const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                        ),
                        if (widget.garment.imageUrls.length > 1) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _currentImageIndex =
                                      (_currentImageIndex -
                                          1 +
                                          widget.garment.imageUrls.length) %
                                      widget.garment.imageUrls.length;
                                });
                              },
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _currentImageIndex =
                                      (_currentImageIndex + 1) %
                                      widget.garment.imageUrls.length;
                                });
                              },
                            ),
                          ),
                        ],
                        if (widget.garment.imageUrls.length > 1)
                          Positioned(
                            bottom: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  widget.garment.imageUrls.asMap().entries.map((
                                    entry,
                                  ) {
                                    return GestureDetector(
                                      onTap:
                                          () => setState(
                                            () =>
                                                _currentImageIndex = entry.key,
                                          ),
                                      child: Container(
                                        width: 8.0,
                                        height: 8.0,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                          horizontal: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.darkGreen.withValues(
                                            alpha:
                                                _currentImageIndex == entry.key
                                                    ? 0.9
                                                    : 0.4,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      widget.garment.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: ResponsiveUtils.fontSize(
                          context,
                          baseSize: 16,
                          tabletMultiplier: 1.1,
                          desktopMultiplier: 1.3,
                          maxSize: 22,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.garment.size != null &&
                                  widget.garment.size!.isNotEmpty)
                                Text(
                                  "Talla: ${widget.garment.size}",
                          
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    fontSize: ResponsiveUtils.fontSize(
                                      context,
                                      baseSize: 13,
                                      tabletMultiplier: 1.1,
                                      desktopMultiplier: 1.3,
                                      maxSize: 17,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (widget.garment.condition != null &&
                                  widget.garment.condition!.isNotEmpty)
                                Text(
                                  "Condición: ${widget.garment.condition}",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    fontSize: ResponsiveUtils.fontSize(
                                      context,
                                      baseSize: 13,
                                      tabletMultiplier: 1.1,
                                      desktopMultiplier: 1.3,
                                      maxSize: 17,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (widget.onInfoTap != null)
                          IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed:
                                widget
                                    .onInfoTap, // Se mantiene para simular acción
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),

                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 6.0,
                    ),
                    child: GestureDetector(
                      onTap:
                          widget
                              .onProfileTap, // Se mantiene para simular acción
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: ResponsiveUtils.fontSize(
                              context,
                              baseSize: 16,
                              tabletMultiplier: 1.1,
                              desktopMultiplier: 1.3,
                              maxSize: 28,
                            ),
                            backgroundColor: Colors.grey[300],
                            // --- SIMULACIÓN DE IMAGEN DE PERFIL ---
                            // backgroundImage: widget.garment.ownerPhotoUrl != null && widget.garment.ownerPhotoUrl!.isNotEmpty
                            //     ? CachedNetworkImageProvider(widget.garment.ownerPhotoUrl!)
                            //     : null,
                            child:
                            /* widget.garment.ownerPhotoUrl == null ||
                                        widget.garment.ownerPhotoUrl!.isEmpty
                                    ?  */
                            Icon(
                              Icons.person,
                              size: ResponsiveUtils.fontSize(
                                context,
                                baseSize: 18,
                                tabletMultiplier: 1.1,
                                desktopMultiplier: 1.3,
                                maxSize: 30,
                              ),
                              color: Colors.white,
                            ),
                            /* : null */
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.garment.ownerUsername,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: ResponsiveUtils.fontSize(
                                  context,
                                  baseSize: 14,
                                  tabletMultiplier: 1.1,
                                  desktopMultiplier: 1.3,
                                  maxSize: 22,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }
}
