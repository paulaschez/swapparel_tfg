
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';

class ProfileGarmentCard extends StatelessWidget {
  const ProfileGarmentCard({
    super.key,
    required this.polaroidWidth,
    required this.polaroidHeight,
    required this.garment,
  });

  final double polaroidWidth;
  final double polaroidHeight;
  final dynamic garment;

  @override
  Widget build(BuildContext context) {
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
  }
}
