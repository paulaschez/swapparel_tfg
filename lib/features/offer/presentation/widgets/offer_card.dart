import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:swapparel/features/offer/data/model/offer_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class OfferCardInChat extends StatelessWidget {
  final OfferModel offer;
  final String currentUserId;
  final Function(OfferModel offer) onAccept;
  final Function(OfferModel offer) onDecline;

  const OfferCardInChat({
    super.key,
    required this.offer,
    required this.currentUserId,
    required this.onAccept,
    required this.onDecline,
  });

  //TODO: MANEJAR FECHAS MENSAJES CON TIMEAGO
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isMyOffer = offer.offeringUserId == currentUserId;
    final bool amIReceiverAndOfferIsPending =
        offer.receivingUserId == currentUserId &&
        offer.status == OfferStatus.pending;

    String headerText;

    if (isMyOffer) {
      headerText = "Has propuesto un intercambio";
    } else {
      headerText = "Te ha propuesto un intercambio:";
    }

    Color cardBackgroundColor;
    Color statusColor;
    String statusText;

    switch (offer.status) {
      case OfferStatus.pending:
        statusText = "Pendiente de respuesta";
        cardBackgroundColor = isMyOffer ? AppColors.lightGreen : Colors.white;
        statusColor = Colors.orange.shade700;
        break;
      case OfferStatus.accepted:
        statusText = "¡Oferta Aceptada!";
        cardBackgroundColor = AppColors.primaryGreen.withValues(alpha: 0.2);
        statusColor = AppColors.darkGreen;
        break;
      case OfferStatus.declined:
        statusText = "Oferta Rechazada";
        cardBackgroundColor = AppColors.likeRed.withValues(alpha: 0.15);
        statusColor = AppColors.likeRed;
        break;
    }

    return Align(
      alignment: isMyOffer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.verticalSpacing(context) * 0.5,
          horizontal: ResponsiveUtils.fontSize(context, baseSize: 8),
        ),
        padding: EdgeInsets.all(
          ResponsiveUtils.fontSize(context, baseSize: 12, maxSize: 16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft:
                isMyOffer
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
            topRight:
                isMyOffer
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
            bottomLeft: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
          ), // Un borde sutil
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headerText,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 14,
                  maxSize: 16,
                ),
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 8),

            _buildSectionTitle(
              context,
              isMyOffer ? "Tus prendas ofrecidas:" : "Prendas que te ofrecen:",
            ),
            _buildGarmentList(context, offer.offeredItems),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 0.7),

            _buildSectionTitle(
              context,
              isMyOffer ? "Prendas que pides:" : "Prendas que te piden:",
            ),
            _buildGarmentList(context, offer.requestedItems),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 0.7),

            const Divider(
              height: 12,
              thickness: 0.5,
              color: AppColors.darkGreen,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveUtils.fontSize(
                      context,
                      baseSize: 12,
                      maxSize: 14,
                    ),
                  ),
                ),
                if (offer.updatedAt != null) // Mostrar solo si updatedAt existe
                  Text(
                    timeago.format(
                      offer.updatedAt!.toDate(),
                      locale: 'es',
                      allowFromNow: true,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: ResponsiveUtils.fontSize(
                        context,
                        baseSize: 10,
                        maxSize: 11,
                      ),
                    ),
                  ),
              ],
            ),

            if (amIReceiverAndOfferIsPending)
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),

            if (amIReceiverAndOfferIsPending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onDecline(offer),
                    child: Text(
                      "Rechazar",
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: ResponsiveUtils.fontSize(
                          context,
                          baseSize: 14,
                          maxSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onAccept(offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.fontSize(
                          context,
                          baseSize: 12,
                          maxSize: 16,
                        ),
                      ),
                    ),
                    child: Text(
                      "Aceptar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.fontSize(
                          context,
                          baseSize: 14,
                          maxSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(
        top: ResponsiveUtils.fontSize(context, baseSize: 6),
        bottom: ResponsiveUtils.fontSize(context, baseSize: 4),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveUtils.fontSize(
            context,
            baseSize: 13,
            maxSize: 15,
          ),
          color: AppColors.darkGreen.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildGarmentList(BuildContext context, List<OfferedItemInfo> items) {
    if (items.isEmpty) {
      return Text(
        " (Ninguna prenda)",
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey[600],
          fontSize: ResponsiveUtils.fontSize(
            context,
            baseSize: 12,
            maxSize: 14,
          ),
        ),
      );
    }

    final double itemHeight = ResponsiveUtils.fontSize(
      context,
      baseSize: 50,
      maxSize: 60,
    );
    final double itemWidth = itemHeight * 0.9;

    return SizedBox(
      height: itemHeight + ResponsiveUtils.fontSize(context, baseSize: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: itemWidth,
            margin: EdgeInsets.only(
              right: ResponsiveUtils.fontSize(context, baseSize: 8),
              top: ResponsiveUtils.fontSize(context, baseSize: 4),
              bottom: ResponsiveUtils.fontSize(context, baseSize: 4),
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!, width: 0.5),
              image:
                  item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? DecorationImage(
                        image: CachedNetworkImageProvider(item.imageUrl!),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Manejo de error para la imagen
                          print(
                            "Error cargando imagen de oferta: ${item.imageUrl}, $exception",
                          );
                        },
                      )
                      : null,
            ),
            child:
                (item.imageUrl == null || item.imageUrl!.isEmpty)
                    ? Icon(
                      Icons.inventory_2_outlined,
                      size: ResponsiveUtils.fontSize(
                        context,
                        baseSize: 24,
                        maxSize: 28,
                      ),
                      color: Colors.grey[400],
                    )
                    : null,
          );
        },
      ),
    );
  }
}
