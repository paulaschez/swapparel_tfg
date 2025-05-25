import 'package:go_router/go_router.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../provider/feed_provider.dart';
import '../widgets/garment_swipe_card.dart';
import '../../../../app/config/theme/app_theme.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      if (feedProvider.garments.isEmpty && !feedProvider.isLoading) {
        print("FeedScreen initState: Calling initializeFeed.");

        feedProvider.initializeFeed();
      }
    });
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  bool _onSwipe(
    int
    previousIndex, // indice de la lista feedProvider.garments que se acaba de swipear
    int? currentIndex, // el nuevo indice que el swiper va a mostrar
    CardSwiperDirection direction,
  ) {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    if (previousIndex < 0 || previousIndex >= feedProvider.garments.length) {
      print("FeedScreen: _onSwipe con previousIndex inválido: $previousIndex");
      return false;
    }

    final swipedGarment = feedProvider.garments[previousIndex];
    Future.delayed(const Duration(milliseconds: 300), () {
      if (direction == CardSwiperDirection.right) {
        print("FeedScreen: Liked: ${swipedGarment.name}");
        feedProvider.swipeRight(swipedGarment);
      } else if (direction == CardSwiperDirection.left) {
        print("FeedScreen: Disliked: ${swipedGarment.name}");
        feedProvider.swipeLeft(swipedGarment);
      }
    });

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();

    final double horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final double verticalSpacing = ResponsiveUtils.largeVerticalSpacing(
      context,
    );

    // Se muestra si no está cargando, la lista de prendas está vacía,
    // Y el provider indica que ya no hay más para cargar.
    final bool showNoMoreCardsMessage =
        !feedProvider.isLoading &&
        feedProvider.garments.isEmpty &&
        !feedProvider.hasMoreGarments;

    // Se muestra si hay prendas, o si está cargando pero ya tiene algunas prendas (para paginación)
    final bool showSwiper =
        feedProvider.garments.isNotEmpty ||
        (feedProvider.isLoading && feedProvider.garments.isNotEmpty);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  feedProvider.isLoading &&
                          feedProvider
                              .garments
                              .isEmpty // Estado de carga inicial
                      ? const Center(child: CircularProgressIndicator())
                      : showNoMoreCardsMessage
                      ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "¡Oh! Parece que no hay prendas nuevas por ahora.\n¡Vuelve más tarde!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(
                                context,
                                baseSize: 16,
                              ),
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ),
                      )
                      : !feedProvider.isLoading &&
                          !showSwiper // No hay más prendas
                      ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "Preparando prendas..",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(
                                context,
                                baseSize: 16,
                              ),
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ),
                      )
                      : CardSwiper(
                        controller: _swiperController,
                        cardsCount: feedProvider.garments.length,
                        onSwipe: _onSwipe,
                        //onUndo: _onUndo,
                        isLoop: false,

                        numberOfCardsDisplayed:
                            feedProvider.garments.isEmpty
                                ? 0
                                : (feedProvider.garments.length < 2 ? 1 : 2),
                        backCardOffset: const Offset(15, 15),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalSpacing,
                        ),
                        allowedSwipeDirection: AllowedSwipeDirection.symmetric(
                          horizontal: true,
                        ),
                        cardBuilder: (
                          context,
                          index,
                          horizontalThresholdPercentage,
                          verticalThresholdPercentage,
                        ) {
                          if (index >= feedProvider.garments.length) {
                            return const SizedBox.shrink();
                          }
                          final garment = feedProvider.garments[index];

                          double iconOpacity = 0.0;
                          double iconScale = 0.5;
                          IconData? feedbackIcon;
                          Color? feedbackIconColor;

                          // Umbral para que el icono alcance su máxima opacidad/escala
                          const double fullEffectThreshold = 100.0;
                          // Umbral mínimo para empezar a mostrar el icono
                          const double visibilityThreshold = 5.0;

                          int progress = horizontalThresholdPercentage.abs();

                          if (progress > visibilityThreshold) {
                            if (horizontalThresholdPercentage > 0) {
                              // Swipe a la DERECHA (Like)
                              feedbackIcon = Icons.favorite_rounded;
                              feedbackIconColor = AppColors.likeRed;
                            } else {
                              // Swipe a la IZQUIERDA (Dislike)
                              feedbackIcon = Icons.close_rounded;
                              feedbackIconColor = Colors.black;
                            }

                            iconOpacity = ((progress - visibilityThreshold) /
                                    (fullEffectThreshold - visibilityThreshold))
                                .clamp(0.0, 1.0);

                            iconScale =
                                0.5 +
                                (0.5 *
                                        ((progress - visibilityThreshold) /
                                            (fullEffectThreshold -
                                                visibilityThreshold)))
                                    .clamp(0.0, 0.5);
                          } else {
                            iconOpacity = 0.0;
                            iconScale = 0.5;
                          }

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              GarmentSwipeCard(
                                garment: garment,
                                onInfoTap: () {
                                  print(
                                    "FeedScreen: Info tap: ${garment.name}. Navegando a pantalla detalle",
                                  );

                                  context.pushNamed(
                                    'garmentDetail',
                                    pathParameters: {'garmentId': garment.id},
                                  );
                                },
                                onProfileTap: () {
                                  print(
                                    "FeedScreen: Profile tap: ${garment.ownerUsername}. Navegando a pantalla del perfil",
                                  );
                                  context.pushNamed(
                                    'profile',
                                    pathParameters: {'userId': garment.ownerId},
                                  );
                                },
                              ),

                              // --- Icono de Feedback Visual (Opacidad y Escala) ---
                              if (feedbackIcon != null && iconOpacity > 0)
                                Positioned.fill(
                                  child: Center(
                                    child: Opacity(
                                      opacity: iconOpacity,
                                      child: Transform.scale(
                                        scale: iconScale,
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          child: Icon(
                                            feedbackIcon,
                                            color: feedbackIconColor,
                                            size: ResponsiveUtils.fontSize(
                                              context,
                                              baseSize: 100,
                                              tabletMultiplier: 1.3,
                                              desktopMultiplier: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
            ),
            if (!(feedProvider.isLoading && feedProvider.garments.isEmpty) &&
                feedProvider
                    .garments
                    .isNotEmpty) // Solo mostrar si hay tarjetas
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: verticalSpacing,
                  horizontal: horizontalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      heroTag: 'dislike_button_feed',
                      onPressed:
                          () =>
                              _swiperController.swipe(CardSwiperDirection.left),
                      backgroundColor: Colors.white,
                      elevation: 4,
                      child: Icon(
                        Icons.close_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                    ),
                    SizedBox(width: 10),
                    FloatingActionButton(
                      heroTag: 'like_button_feed',
                      onPressed:
                          () => _swiperController.swipe(
                            CardSwiperDirection.right,
                          ),
                      backgroundColor: AppColors.likeRed,
                      elevation: 4,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: AppColors.background,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // TODO: Implementar Undo? Requiere deshacer todo en el feed provider.
  // O Solo Hacer la acción una vez que se haya swipeado ya otra prenda
  //( no se podría hacer undo a dicha prenda ya )

  /* bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    print('SIMULACIÓN: Undid ${direction.name}');
    return true;
  } */
}
