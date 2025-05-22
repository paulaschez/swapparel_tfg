import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Comentado ya que no se usará activamente
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swapparel/features/auth/data/models/user_model.dart';
// import 'package:carousel_slider/carousel_slider.dart'; // O tu paquete de carrusel
import '../../../../app/config/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/models/garment_model.dart';
// import '../provider/garment_detail_provider.dart'; // Comentado
// import '../../../auth/presentation/provider/auth_provider.dart'; // Comentado
//import '../../../../app/config/routes/app_routes.dart';
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

  // --- DATOS DE EJEMPLO ---
  // Puedes cambiar estos datos para probar diferentes escenarios de UI

  // Escenario 1: Es mi prenda
  final GarmentModel _ejemploGarment = GarmentModel(
    id: "myGarment001",
    name: "Chaqueta de Cuero Clásica",
    description:
        "Una chaqueta de cuero sintético resistente y con estilo. Varios bolsillos y forro interior. Ideal para un look rockero o casual.",
    imageUrls: [
      "https://images.unsplash.com/photo-1551028719-00167b16eac5?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8bGVhdGhlciUyMGphY2tldHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
      "https://m.media-amazon.com/images/I/819qkPq4bML._AC_SX342_.jpg",
      "https://m.media-amazon.com/images/I/819qkPq4bML._AC_SX342_.jpg",
      "https://m.media-amazon.com/images/I/712AYBPWjPL._AC_SX342_.jpg",
    ],
    category: "Chaquetas",
    size: "L",
    condition: "Usado con detalles",
    brand: "Rockstar Gear",
    color: "Negro",
    material: "Cuero sintético",
    ownerId: "currentUser123", // ID del usuario "actual"
    ownerUsername: "YoMismoCool",
    ownerPhotoUrl:
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cG9ydHJhaXQlMjBtYW58ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=100&q=60",
    createdAt: Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 30)),
    ),
  );
  final String _currentUserIdEjemplo =
      "currentUser123"; // Para simular que soy el dueño
  final bool _isLoadingEjemplo = false; // Simula que la carga ha terminado
  final String? _errorMessageEjemplo = null; // Simula que no hay error

  /* // // Escenario 2: Prenda de otro usuario
   final GarmentModel _ejemploGarment = GarmentModel(
     id: "garmentXYZ123",
     name: "Vestido Floral Veraniego",
     description: "Vestido ligero y fresco, perfecto para días soleados. Estampado floral vibrante. Casi nuevo.",
     imageUrls: [
       "https://images.unsplash.com/photo-1586790170183-9a0f86026169?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8c3VtbWVyJTIwZHJlc3N8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60",
       "https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8c3VtbWVyJTIwZHJlc3N8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60",
     ],
     category: "Vestidos",
     size: "M",
     condition: "Como nuevo",
     brand: "SolModa",
    color: "Multicolor (Floral)",
     material: "Algodón",
     ownerId: "userABC789", // ID del propietario (diferente al usuario actual)
     ownerUsername: "AnaSol",
   ownerPhotoUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cG9ydHJhaXQlMjB3b21hbnxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=100&q=60",
     createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))) ,
   );
   final String _currentUserIdEjemplo = "someOtherUser456"; // Para simular que NO soy el dueño
   final bool _isLoadingEjemplo = false;
  final String? _errorMessageEjemplo = null; */

  /*  // Escenario 3: Cargando
   final GarmentModel? _ejemploGarment = null;
   final String _currentUserIdEjemplo = "currentUser123";
   final bool _isLoadingEjemplo = true;
   final String? _errorMessageEjemplo = null; */

  /* // Escenario 4: Error
   final GarmentModel? _ejemploGarment = null;
   final String _currentUserIdEjemplo = "currentUser123";
   final bool _isLoadingEjemplo = false;
   final String? _errorMessageEjemplo = "Error al cargar los datos de la prenda. Inténtalo más tarde."; */

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // Cargar los detalles de la prenda al iniciar la pantalla
    //   // Provider.of<GarmentDetailProvider>(context, listen: false)
    //   //     .fetchGarmentDetails(widget.garmentId);
    // });
      _pageController = PageController(initialPage: 0);

  }

  @override
  void dispose(){
    _pageController.dispose();
    super.dispose();
  }

  bool isLiked = true;

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

late final PageController _pageController;

  

  @override
  Widget build(BuildContext context) {
    // --- USO DE DATOS DE EJEMPLO EN LUGAR DE PROVIDER ---
    // final garmentDetailProvider = context.watch<GarmentDetailProvider>();
    // final authProvider = context.watch<AuthProviderC>();

    final GarmentModel? garment =
        _ejemploGarment; // Usamos el ejemplo definido arriba
    // final UserModel? owner = null; // Si GarmentDetailProvider lo poblaba, aquí sería null o un ejemplo
    final bool isLoading = _isLoadingEjemplo; // Usamos el ejemplo
    final String? errorMessage = _errorMessageEjemplo; // Usamos el ejemplo

    final bool isMyGarment =
        garment != null &&
        _currentUserIdEjemplo == garment.ownerId; // Usamos el ID de ejemplo

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
              ), // Icono de tres puntos verticales
              onSelected: (String result) {
                // Lógica para manejar la selección del menú
                if (result == editOption) {
                  print("Simulación: Editar prenda ${garment.id}");
                  // TODO: Navegar a EditGarmentScreen(garment: garment)
                } else if (result == deleteOption) {
                  print(
                    "Simulación: Mostrar diálogo para borrar prenda ${garment.id}",
                  );
                  // Aquí podrías llamar a una función que muestre el diálogo de confirmación
                  // Ejemplo: _showDeleteConfirmDialog(context, garment);
                  // Por ahora, solo un print:
                  // bool? confirmed = await showDialog... (como tenías antes)
                  // if (confirmed == true) { print("Prenda borrada..."); if(mounted) context.pop(); }
                }
              },
              borderRadius: BorderRadius.circular(20),
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: editOption,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
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
                                return Image.network(
                                  garment.imageUrls[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              },
                            ),
                          ),
                        ),
                        // Botón de Like
                        if (isMyGarment)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                setState(() {
                                  isLiked = !isLiked;
                                });
                              },
                            ),
                          ),

                        // Puntos de navegación
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

                    if (garment.description != null &&
                        garment.description!.isNotEmpty) ...[
                      SizedBox(
                        height: ResponsiveUtils.verticalSpacing(context),
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildChip("Talla", garment.size!),
                        SizedBox(
                          width:
                              ResponsiveUtils.horizontalPadding(context) * 0.5,
                        ),
                        _buildChip("Condición", garment.condition!),
                      ],
                    ),

                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(garment.category ?? '-')),
                        Chip(label: Text(garment.brand ?? '-')),
                        Chip(label: Text(garment.color ?? '-')),
                        Chip(label: Text(garment.material ?? '-')),
                      ],
                    ),

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
                        onTap: () => print("Navegando a perfil"),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  garment.ownerPhotoUrl != null
                                      ? NetworkImage(garment.ownerPhotoUrl!)
                                      : null,
                              radius:
                                  ResponsiveUtils.avatarRadius(context) * 0.5,
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
