import 'dart:async';

import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; 
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
// import '../provider/feed_provider.dart'; 
import '../widgets/garment_swipe_card.dart';
import '../../../garment/data/models/garment_model.dart'; //  para los datos de ejemplo
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../../../app/config/theme/app_theme.dart'; 
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  // --- DATOS DE EJEMPLO ---
  final List<GarmentModel> _exampleGarments = [];
  bool _isLoadingExample = true; 
  int _swipeCount = 0;

  @override
  void initState() {
    super.initState();
    // --- CARGA DE DATOS DE EJEMPLO ---
    _loadExampleGarments();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    //   if (feedProvider.garments.isEmpty && !feedProvider.isLoading) {
    //     feedProvider.initializeFeed();
    //   }
    // });
  }

  void _loadExampleGarments() {
    // Simula una carga con retraso
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _exampleGarments.addAll(
          List.generate(
            10, // Número de prendas de ejemplo
            (index) => GarmentModel(
              id: 'garment_id_$index',
              ownerId: 'owner_id_$index',
              ownerUsername: '@user_example_$index',
              ownerPhotoUrl: "https://picsum.photos/seed/user$index/50/50",
              name: 'Prenda Atractiva $index $_swipeCount',
              imageUrls: List.generate(
                index % 4 + 1,
                (imgIdx) => 'url_img_${index}_$imgIdx',
              ), // 1 a 4 imágenes
              size: 'M',
              condition: index % 2 == 0 ? 'Como Nuevo' : 'Buen Estado',
              category: 'Camisa',
              createdAt: Timestamp.now(),
              isAvailable: true,
              // description, brand, color, material pueden ser null
            ),
          ),
        );
        _isLoadingExample = false;
      });
    });
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (previousIndex >= 0 && previousIndex < _exampleGarments.length) {
      final swipedGarment = _exampleGarments[previousIndex];
      if (direction == CardSwiperDirection.right) {
        print("SIMULACIÓN: Liked: ${swipedGarment.name}");
        // Provider.of<FeedProvider>(context, listen: false).swipeRight(swipedGarment);
      } else if (direction == CardSwiperDirection.left) {
        print("SIMULACIÓN: Disliked: ${swipedGarment.name}");
        // Provider.of<FeedProvider>(context, listen: false).swipeLeft(swipedGarment);
      }

      // Incrementar el contador de swipes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _swipeCount++;
          });
        }
      });
    }

    /* if (currentIndex != null && _exampleGarments.length - _swipeCount < 3) {
      //&& // Menos de 3 restantes
      //     !_isLoadingExample /*&& feedProvider.hasMoreGarments && !feedProvider.isLoading*/) {
      setState(() {
        _loadExampleGarments();
      });(); 
      TODO FUNCIÓN PARA AÑADIR MÁS A LA LISTA
      //   // Provider.of<FeedProvider>(context, listen: false).fetchMoreGarments();
    } */
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // final feedProvider = context.watch<FeedProvider>();

    // Tamaños y espaciados responsivos
    final double horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final double verticalSpacing = ResponsiveUtils.largeVerticalSpacing(
      context,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  _isLoadingExample &&
                          _exampleGarments
                              .isEmpty // Estado de carga inicial
                      ? const Center(child: CircularProgressIndicator())
                      : _swipeCount >= _exampleGarments.length &&
                          !_isLoadingExample // No hay más prendas
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
                      : CardSwiper(
                        controller: _swiperController,
                        cardsCount: _exampleGarments.length,
                        onSwipe: _onSwipe,
                        onUndo: _onUndo,
                        isLoop: false,
                        numberOfCardsDisplayed:
                            _exampleGarments.length < 2 ? 1 : 2,
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
                          if (index >= _exampleGarments.length) {
                            return const SizedBox.shrink();
                          }
                          final garment = _exampleGarments[index];

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
                                    "SIMULACIÓN: Info tap: ${garment.name}",
                                  );
                                  // TODO: Navegar a GarmentDetailScreen(garment: garment)
                                },
                                onProfileTap: () {
                                  print(
                                    "SIMULACIÓN: Profile tap: ${garment.ownerUsername}",
                                  );
                                  // TODO: Navegar a ProfileScreen(userId: garment.ownerId, isCurrentUserProfile: false)
                                },
                              ),

                              // --- Icono de Feedback Visual (Opacidad y Escala) ---
                              if (feedbackIcon != null &&
                                  iconOpacity >
                                      0) 
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
            if (_exampleGarments.length != _swipeCount &&
                !_isLoadingExample) // Solo mostrar si hay tarjetas
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

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    print('SIMULACIÓN: Undid ${direction.name}');
    return true;
  }
}
