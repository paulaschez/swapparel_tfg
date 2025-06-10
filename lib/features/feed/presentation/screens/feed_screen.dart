import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/match/data/models/match_model.dart';
import 'package:swapparel/features/match/presentation/provider/match_provider.dart';
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

  Future<void> _showMatchDialog(MatchModel match) async {
    print("UI: ¡ES UN MATCH! Mostrando feedback para match ID: ${match.id}");
    // --- Obtener datos del OTRO participante del MatchModel ---
    String otherUserId = '';
    String otherUserName = "Alguien"; // Fallback name
    String? otherUserPhotoUrl; // Fallback photo
    String currentUserName = "Tú"; // Fallback para el usuario actual

    final authProvider = Provider.of<AuthProviderC>(context, listen: false);
    if (authProvider.currentUserModel != null) {
      currentUserName =
          authProvider.currentUserModel!.name; // Nombre del usuario actual
    }

    if (match.participantIds.length == 2 &&
        authProvider.currentUserId != null) {
      otherUserId = match.participantIds.firstWhere(
        (id) => id != authProvider.currentUserId,
        orElse:
            () =>
                '', // Devuelve una cadena vacía si no se encuentra (no debería pasar si hay 2 IDs)
      );
    }

    if (otherUserId.isNotEmpty &&
        match.participantDetails != null &&
        match.participantDetails!.containsKey(otherUserId)) {
      final details = match.participantDetails![otherUserId]!;
      otherUserName = details['name'] ?? otherUserName;
      otherUserPhotoUrl = details['photoUrl'];
    }
    // --- Fin de la obtención de datos ---

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.lightGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            "¡Es un Match! 🎉",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveUtils.fontSize(
                context,
                baseSize: 20,
                maxSize: 24,
              ),
              color: AppColors.darkGreen,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: ResponsiveUtils.avatarRadius(context) * 0.3,
                    backgroundColor: Colors.grey[400],
                    backgroundImage:
                        authProvider.currentUserModel?.photoUrl != null &&
                                authProvider
                                    .currentUserModel!
                                    .photoUrl!
                                    .isNotEmpty
                            ? CachedNetworkImageProvider(
                              authProvider.currentUserModel!.photoUrl!,
                            )
                            : null,
                    child:
                        authProvider.currentUserModel?.photoUrl == null ||
                                authProvider.currentUserModel!.photoUrl!.isEmpty
                            ? Icon(
                              Icons.person,
                              size:
                                  ResponsiveUtils.avatarRadius(context) * 0.25,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.favorite,
                      color: AppColors.likeRed,
                      size: 28,
                    ),
                  ),
                  CircleAvatar(
                    radius: ResponsiveUtils.avatarRadius(context) * 0.3,
                    backgroundColor: Colors.grey[400],
                    backgroundImage:
                        otherUserPhotoUrl != null &&
                                otherUserPhotoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(otherUserPhotoUrl)
                            : null,
                    child:
                        otherUserPhotoUrl == null || otherUserPhotoUrl.isEmpty
                            ? Icon(
                              Icons.person,
                              size:
                                  ResponsiveUtils.avatarRadius(context) * 0.25,
                              color: Colors.white,
                            )
                            : null,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                "¡Felicidades, $currentUserName!\nHas hecho match con $otherUserName.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(
                    context,
                    baseSize: 16,
                    maxSize: 18,
                  ),
                  color: AppColors.darkGreen.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actionsPadding: const EdgeInsets.only(
            right: 16.0,
            left: 16.0,
            bottom: 12.0,
            top: 8.0,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Seguir Viendo",
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(
                    context,
                    baseSize: 14,
                    maxSize: 16,
                  ),
                  color: AppColors.darkGreen.withValues(alpha: 0.7),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop('continue'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(
                    context,
                    baseSize: 14,
                    maxSize: 16,
                  ),
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text("Ir al Chat"),
              onPressed: () => Navigator.of(dialogContext).pop('chat'),
            ),
          ],
        );
      },
    );

    if (result == 'chat') {
      print(
        "Navegando al chat del match: ${match.id} con $otherUserName (ID: $otherUserId)",
      );
      context.pushNamed(
        'chatConversation',
        pathParameters: {'chatId': match.id},
        extra: {
          'otherUserName': otherUserName,
          'otherUserPhotoUrl': otherUserPhotoUrl,
          'otherUserId': otherUserId,
        },
      );
    } else if (result == 'continue') {
      print("Usuario eligió continuar viendo prendas.");
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  bool _onSwipe(
    int
    previousIndex, // indice de la lista feedProvider.garments que se acaba de swipear
    int?
    currentIndex, // el nuevo indice que el swiper va a mostrar despues del swipe
    CardSwiperDirection direction,
  ) {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    if (previousIndex < 0 || previousIndex >= feedProvider.garments.length) {
      print("FeedScreen: _onSwipe con previousIndex inválido: $previousIndex");
      return false;
    }

    final swipedGarment = feedProvider.garments[previousIndex];
    if (direction == CardSwiperDirection.right) {
      print("FeedScreen: Liked: ${swipedGarment.name}");
      feedProvider.swipeRight(swipedGarment);
    } else if (direction == CardSwiperDirection.left) {
      print("FeedScreen: Disliked: ${swipedGarment.name}");
      feedProvider.swipeLeft(swipedGarment);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final matchProvider = context.watch<MatchProvider>();

    if (matchProvider.showMatchFeedback &&
        matchProvider.lastCreatedMatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && matchProvider.showMatchFeedback) {
          print("FeedScreen build: Mostrando diálogo de match.");
          _showMatchDialog(matchProvider.lastCreatedMatch!);
          matchProvider.consumeMatchFeedback();
        }
      });
    }

    final double horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final double verticalSpacing = ResponsiveUtils.largeVerticalSpacing(
      context,
    );

    Widget feedContent;

    if (feedProvider.isLoading && feedProvider.garments.isEmpty) {
      // Carga inicial, pantalla vacía, mostrar loader grande en el centro
      print(
        "FeedScreen build: Estado - Carga Inicial o fetching más(sin prendas aún)",
      );
      feedContent = const Center(child: CircularProgressIndicator());
    } else if (feedProvider.garments.isNotEmpty) {
      // Hay prendas para mostrar, o se están cargando más en segundo plano
      print(
        "FeedScreen build: Estado - Mostrando CardSwiper (prendas: ${feedProvider.garments.length}, isLoading: ${feedProvider.isLoading})",
      );

      feedContent = CardSwiper(
        key: ValueKey(feedProvider.garments.hashCode),
        controller: _swiperController,
        cardsCount: feedProvider.garments.length,
        onSwipe: _onSwipe,
        onEnd: () {
          feedProvider.fetchMoreGarments();
        },
        isLoop: false,
        numberOfCardsDisplayed:
            feedProvider.garments.length < 2 ? 1 : 2, // Muestra 1 o 2
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
              feedbackIconColor = Colors.blueGrey;
            }

            iconOpacity = ((progress - visibilityThreshold) /
                    (fullEffectThreshold - visibilityThreshold))
                .clamp(0.0, 1.0);

            iconScale =
                0.5 +
                (0.5 *
                        ((progress - visibilityThreshold) /
                            (fullEffectThreshold - visibilityThreshold)))
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
      );
    } else if (!feedProvider.hasMoreGarments && feedProvider.garments.isEmpty) {
      // No hay más prendas en absoluto Y la lista está vacía (después de intentar cargar y no encontrar)
      print(
        "FeedScreen build: Estado - No hay más prendas y la lista está vacía.",
      );
      feedContent = Center(
        child: Text(
          "¡Oh! Parece que no hay prendas nuevas por ahora...",
          textAlign: TextAlign.center,
        ),
      );
    } else {
      print(
        "FeedScreen build: Estado - Inesperado o Preparando (hasMore: ${feedProvider.hasMoreGarments}, garmentsEmpty: ${feedProvider.garments.isEmpty}, isLoading: ${feedProvider.isLoading})",
      );
      feedContent = Center(
        child: Text(feedProvider.errorMessage ?? "Preparando prendas..."),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: feedContent),
            if (feedProvider.garments.isNotEmpty ||
                (feedProvider.isLoading &&
                    feedProvider
                        .garments
                        .isNotEmpty)) // Solo mostrar si hay tarjetas
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
}
