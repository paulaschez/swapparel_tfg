import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:swapparel/features/feed/presentation/provider/feed_provider.dart';
import 'package:swapparel/features/garment/data/repositories/garment_repository.dart';
import 'package:swapparel/features/offer/data/model/offer_model.dart';
import 'package:swapparel/features/offer/presentation/provider/offer_provider.dart';
import 'package:swapparel/features/profile/data/repositories/profile_repository.dart';
import 'package:swapparel/features/profile/presentation/widgets/profile_garment_card.dart';
import '../../../../app/config/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../garment/data/models/garment_model.dart';

class CreateOfferScreen extends StatefulWidget {
  final String matchId;
  final String
  offeringUserId; // El ID del usuario actual que está haciendo la oferta
  final String receivingUserId; // El ID del otro usuario en el match
  final String receivingUsername; // Para mostrar en la UI

  const CreateOfferScreen({
    super.key,
    required this.matchId,
    required this.offeringUserId,
    required this.receivingUserId,
    required this.receivingUsername,
  });

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  List<GarmentModel> _myAvailableGarmentsToOffer = [];
  List<GarmentModel> _otherUserGarmentsThatILikedAndAreAvailable = [];
  final Set<String> _selectedMyGarmentIds = {};
  final Set<String> _selectedOtherUserGarmentIds = {};
  bool _isLoadingMyGarments = true;
  bool _isLoadingOtherUserGarments = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(
        "CreateOfferScreen: initState - Calling OfferCreationProvider to load data.",
      );

      _fetchDataForOffer();
    });
  }

  Future<void> _fetchDataForOffer() async {
    print("CreateOfferScreen: _fetchDataForOffer CALLED.");
    print(
      "CreateOfferScreen: offeringUserId: ${widget.offeringUserId}, receivingUserId: ${widget.receivingUserId}",
    );

    //  1. Cargar mis prendas disponibles
    setState(() => _isLoadingMyGarments = true);
    final profileRepo = Provider.of<ProfileRepository>(context, listen: false);
    print(
      "CreateOfferScreen: Attempting to load MY available garments for user ${widget.offeringUserId}.",
    );

    try {
      _myAvailableGarmentsToOffer = await profileRepo.getUserUploadedGarments(
        widget.offeringUserId,
        limit: 100,
        isAvailable: true,
      );
      print(
        "CreateOfferScreen: SUCCESSFULLY loaded ${_myAvailableGarmentsToOffer.length} of MY available garments.",
      );
    } catch (e) {
      print("CreateOfferScreen: ERROR loading MY available garments: $e");
      _myAvailableGarmentsToOffer = [];
    } finally {
      if (mounted) setState(() => _isLoadingMyGarments = false);
    }

    //  2. Cargar prendas del otro Usuario que a mi me Gustaron y están disponibles
    setState(() => _isLoadingOtherUserGarments = true);
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final garmentRepo = Provider.of<GarmentRepository>(context, listen: false);
    print(
      "CreateOfferScreen: Attempting to load OTHER USER'S liked and available garments.",
    );

    try {
      // a. Obtener los IDs de TODAS las prendas a las que YO (offeringUserId) les di like
      final Set<String> myLikedGarmentIds =
          feedProvider.currentUserLikedGarmentIds;
      print(
        "CreateOfferScreen: Current user (${widget.offeringUserId}) has liked ${myLikedGarmentIds.length} garment IDs in total: $myLikedGarmentIds",
      );

      if (myLikedGarmentIds.isNotEmpty) {
        // b. Obtener los GarmentModels completos para esos IDs
        print(
          "CreateOfferScreen: Fetching GarmentModels for ${myLikedGarmentIds.length} liked IDs.",
        );
        List<GarmentModel> potentialLikedGarments = await garmentRepo
            .getMultipleGarmentsByIds(myLikedGarmentIds.toList());
        print(
          "CreateOfferScreen: Fetched ${potentialLikedGarments.length} GarmentModels from liked IDs.",
        );
        if (potentialLikedGarments.isNotEmpty) {
          potentialLikedGarments
              .take(2)
              .forEach(
                (g) => print(
                  "   Potential Garment: ${g.name}, ID: ${g.id}, Owner: ${g.ownerId}, Available: ${g.isAvailable}",
                ),
              );
        }

        // c. Filtrar para mostrar solo las que son del 'receivingUserId' Y están disponibles
        print(
          "CreateOfferScreen: Filtering potential liked garments. Target ownerId: ${widget.receivingUserId}, must be available.",
        );
        _otherUserGarmentsThatILikedAndAreAvailable =
            potentialLikedGarments.where((garment) {
              bool isOwnerMatch = garment.ownerId == widget.receivingUserId;
              bool isGarmentAvailable = garment.isAvailable == true;
              print(
                "   Filtering Garment: ${garment.name} (ID: ${garment.id}) - Owner: ${garment.ownerId} (Match: $isOwnerMatch), Available: ${garment.isAvailable} (Match: $isGarmentAvailable)",
              );
              return isOwnerMatch && isGarmentAvailable;
            }).toList();
        print(
          "CreateOfferScreen: AFTER filtering, found ${_otherUserGarmentsThatILikedAndAreAvailable.length} garments from other user that I liked and are available.",
        );
      } else {
        print(
          "CreateOfferScreen: Current user has no liked garments, so no prendas from other user to display.",
        );
        _otherUserGarmentsThatILikedAndAreAvailable = [];
      }
    } catch (e) {
      print(
        "CreateOfferScreen: ERROR loading liked and available garments from other user: $e",
      );
      _otherUserGarmentsThatILikedAndAreAvailable = [];
    } finally {
      if (mounted) setState(() => _isLoadingOtherUserGarments = false);
    }
    print("CreateOfferScreen: _fetchDataForOffer COMPLETED.");
  }

  void _toggleSelection(String garmentId, bool isMyGarment) {
    setState(() {
      if (isMyGarment) {
        if (_selectedMyGarmentIds.contains(garmentId)) {
          _selectedMyGarmentIds.remove(garmentId);
        } else {
          _selectedMyGarmentIds.add(garmentId);
        }
      } else {
        if (_selectedOtherUserGarmentIds.contains(garmentId)) {
          _selectedOtherUserGarmentIds.remove(garmentId);
        } else {
          _selectedOtherUserGarmentIds.add(garmentId);
        }
      }
    });
  }

  void _sendOffer() async {
    if (_selectedMyGarmentIds.isEmpty || _selectedOtherUserGarmentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona al menos una prenda de cada lado."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    List<OfferedItemInfo> myOfferedItems =
        _selectedMyGarmentIds.map((id) {
          final garment = _myAvailableGarmentsToOffer.firstWhere(
            (g) => g.id == id,
          );
          return OfferedItemInfo(
            garmentId: garment.id,
            name: garment.name,
            imageUrl:
                garment.imageUrls.isNotEmpty ? garment.imageUrls[0] : null,
          );
        }).toList();

    List<OfferedItemInfo> theirRequestedItems =
        _selectedOtherUserGarmentIds.map((id) {
          final garment = _otherUserGarmentsThatILikedAndAreAvailable
              .firstWhere((g) => g.id == id);
          return OfferedItemInfo(
            garmentId: garment.id,
            name: garment.name,
            imageUrl:
                garment.imageUrls.isNotEmpty ? garment.imageUrls[0] : null,
          );
        }).toList();

    print("Enviando oferta:");
    print("   Ofrezco: ${myOfferedItems.map((e) => e.name).join(', ')}");
    print("   Pido: ${theirRequestedItems.map((e) => e.name).join(', ')}");

    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    bool success = await offerProvider.sendNewOffer(
      matchId: widget.matchId,
      receivingUserId: widget.receivingUserId,
      myOfferedItems: myOfferedItems,
      theirRequestedItems: theirRequestedItems,
    );

    if (mounted) {
      if (success) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(" Oferta enviada")));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Ha ocurrido un error y no se ha podido enviar la oferta",
            ),
          ),
        );
        context.pop();
      }
    }
  }

  Widget _buildGarmentSelectionGrid(
    BuildContext context,
    String title,
    List<GarmentModel> garments,
    Set<String> selectedIds,
    bool isLoading,
    bool isMyGarmentList,
  ) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (garments.isEmpty && !isLoading) {
      return Center(child: Text("No hay prendas disponibles para \"$title\"."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.verticalSpacing(context) * 0.8,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: ResponsiveUtils.fontSize(
                context,
                baseSize: 18,
                maxSize: 20,
              ),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;

            final int crossAxisCount;
            if (availableWidth >= 700) {
              crossAxisCount = 4;
            } else if (availableWidth >= 500) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }

            final double gridItemSpacing = availableWidth * 0.02;
            final double cellAspectRatio = 0.75; // (Ancho / Alto)

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: gridItemSpacing,
                mainAxisSpacing: gridItemSpacing,
                childAspectRatio: cellAspectRatio,
              ),
              itemCount: garments.length,
              itemBuilder: (context, index) {
                final garment = garments[index];
                final bool isSelected = selectedIds.contains(garment.id);
                return GestureDetector(
                  onTap: () => _toggleSelection(garment.id, isMyGarmentList),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProfileGarmentCard(garment: garment),
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.35,
                              ),
                              border: Border.all(
                                color: AppColors.darkGreen,
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit =
        _selectedMyGarmentIds.isNotEmpty &&
        _selectedOtherUserGarmentIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text("Proponer Intercambio"),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed:
                canSubmit
                    ? _sendOffer
                    : null, // Deshabilitar si no se puede enviar
            child: Text(
              "Enviar",
              style: TextStyle(
                color: canSubmit ? AppColors.darkGreen : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.fontSize(context, baseSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
        child: Column(
          children: [
            _buildGarmentSelectionGrid(
              context,
              "Mis Prendas a Ofrecer",
              _myAvailableGarmentsToOffer,
              _selectedMyGarmentIds,
              _isLoadingMyGarments,
              true,
            ),
            SizedBox(
              height: ResponsiveUtils.largeVerticalSpacing(context) * 1.5,
            ),
            const Divider(thickness: 1.5),
            SizedBox(
              height: ResponsiveUtils.largeVerticalSpacing(context) * 1.5,
            ),
            _buildGarmentSelectionGrid(
              context,
              "Prendas que Pido de @${widget.receivingUsername}",
              _otherUserGarmentsThatILikedAndAreAvailable,
              _selectedOtherUserGarmentIds,
              _isLoadingOtherUserGarments,
              false,
            ),
            SizedBox(height: ResponsiveUtils.largeVerticalSpacing(context) * 2),
          ],
        ),
      ),
    );
  }
}
