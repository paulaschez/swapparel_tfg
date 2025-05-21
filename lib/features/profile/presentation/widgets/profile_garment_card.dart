import 'package:cached_network_image/cached_network_image.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:swapparel/features/garment/data/models/garment_model.dart';

class ProfileGarmentCard extends StatelessWidget {
  const ProfileGarmentCard({
    super.key,
    required this.garment,
  });

  final GarmentModel garment;

  @override
  Widget build(BuildContext context) {
    String? imageUrlToShow;
    if (garment.imageUrls.isNotEmpty) {
      imageUrlToShow = garment.imageUrls[0];
    }
    return Container(
      padding: EdgeInsets.all(8),

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1 / 1, // Imagen cuadrada
            child: Container(
              color: Colors.white, // Placeholder
              child:
                  imageUrlToShow != null && imageUrlToShow.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: imageUrlToShow,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color:
                                  Colors
                                      .grey[200], // Placeholder mientras carga
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height:
                                      20, // Tamaño más pequeño para el loader
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => const Icon(
                              Icons
                                  .broken_image_outlined, // Icono de error más sutil
                              color: Colors.grey,
                              size: 30,
                            ),
                      )
                      : const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
            ),
          ),

          // Nombre de la prenda
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centra verticalmente
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    garment.name,
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
  }
}
