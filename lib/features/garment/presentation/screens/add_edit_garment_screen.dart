import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:swapparel/core/utils/image_picker_utils.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/garment/data/models/garment_model.dart';
import 'package:swapparel/features/garment/presentation/provider/garment_detail_provider.dart';
import 'package:swapparel/features/garment/presentation/provider/garment_provider.dart';
import 'package:swapparel/features/profile/presentation/provider/profile_provider.dart';
import '../../../../app/config/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;

class AddEditGarmentScreen extends StatefulWidget {
  final String? garmentIdForEditing;
  const AddEditGarmentScreen({super.key, this.garmentIdForEditing});
  bool get isEditing => garmentIdForEditing != null;

  @override
  State<AddEditGarmentScreen> createState() => _AddEditGarmentScreenState();
}

class _AddEditGarmentScreenState extends State<AddEditGarmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de los campos del formulario
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();

  // Variables de estado para selectores e imagenes
  String? _selectedCategory;
  String? _selectedSize;
  String? _selectedCondition;
  // En _AddEditGarmentScreenState
  List<EditableImage> _displayedImages = []; // Lista principal para la UI
  final List<String> _imageUrlsToDeleteFromStorage = [];
  // URLs de Storage a borrar al guardar
  final List<XFile> _newXFilesToUpload = []; // Nuevos XFiles a subir al guardar

  final List<String> _categories = [
    'Camisa',
    'Pantalón',
    'Vestido',
    'Falda',
    'Accesorio',
    'Calzado',
    'Chaqueta',
    'Jersey',
    'Abrigo',
    'Otro',
  ];
  final List<String> _sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'Única',
    '36',
    '38',
    '40',
    '42',
    'Otro',
  ];
  final List<String> _conditions = [
    'Nuevo con etiquetas',
    'Como nuevo',
    'Buen estado',
    'Usado con detalles',
  ];

  bool _isLoadingData = false;
  GarmentModel? _garmentBeingEdited;
  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final garmentDetailProvider = Provider.of<GarmentDetailProvider>(
          context,
          listen: false,
        );

        // Comprobar si el provider tiene la prenda correcta
        if (garmentDetailProvider.garment != null &&
            garmentDetailProvider.garment!.id == widget.garmentIdForEditing) {
          print(
            "AddEditGarmentScreen: Usando GarmentModel existente del GarmentDetailProvider.",
          );

          setState(() {
            _garmentBeingEdited = garmentDetailProvider.garment;
            _populateControllersAndImages(_garmentBeingEdited!);
            _isLoadingData = false;
          });
        } else {
          // Si no está o es diferente, cargarla
          print(
            "AddEditGarmentScreen: GarmentModel no disponible o diferente en Provider. Cargando...",
          );
          setState(() => _isLoadingData = true);
          await garmentDetailProvider.fetchGarmentDetails(
            widget.garmentIdForEditing!,
          );

          if (mounted && garmentDetailProvider.garment != null) {
            setState(() {
              _garmentBeingEdited = garmentDetailProvider.garment;
              _populateControllersAndImages(_garmentBeingEdited!);
              _isLoadingData = false;
            });
          } else if (mounted) {
            setState(() => _isLoadingData = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Error al cargar datos de la prenda: ${garmentDetailProvider.errorMessage ?? 'Desconocido'}",
                ),
                backgroundColor: AppColors.error,
              ),
            );
            if (context.canPop()) context.pop();
          }
        }
      });
    }
  }

  void _populateControllersAndImages(GarmentModel garment) {
    print(
      "AddEditGarmentScreen: Poblando controllers con datos de ${garment.name}",
    );
    _nameController.text = garment.name;
    _descriptionController.text = garment.description ?? '';
    _selectedCategory = garment.category;
    _brandController.text = garment.brand ?? '';
    _colorController.text = garment.color ?? '';
    _selectedCondition = garment.condition;
    _selectedSize = garment.size;
    _materialController.text = garment.material ?? '';
    _displayedImages =
        garment.imageUrls.map((url) => EditableImage.network(url)).toList();
    _imageUrlsToDeleteFromStorage.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  Future<void> _handleImageSelection() async {
    final imageUtils = ImagePickerUtils();
    final XFile? pickedXFile = await imageUtils.pickImage(context);

    if (pickedXFile != null) {
      if (_displayedImages.length < 5) {
        setState(() {
          if (kIsWeb) {
            pickedXFile.readAsBytes().then((bytes) {
              if (mounted) {
                setState(() {
                  _displayedImages.add(EditableImage.web(pickedXFile, bytes));
                  _newXFilesToUpload.add(pickedXFile);
                });
              }
            });
          } else {
            _displayedImages.add(EditableImage.file(pickedXFile));
            _newXFilesToUpload.add(pickedXFile);
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Puedes subir un máximo de 5 imágenes."),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      EditableImage imageToRemove = _displayedImages[index];
      _displayedImages.removeAt(index);

      if (imageToRemove.type == ImageSourceType.network &&
          imageToRemove.networkUrl != null) {
        _imageUrlsToDeleteFromStorage.add(imageToRemove.networkUrl!);
      } else if (imageToRemove.localXFile != null) {
        _newXFilesToUpload.remove(imageToRemove.localXFile);
      }
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoadingData = true;
    });
    if (!widget.isEditing &&
        _displayedImages
            .where((img) => img.type != ImageSourceType.network)
            .toList()
            .isEmpty &&
        _displayedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos una imagen.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      setState(() {
        _isLoadingData = false;
      });
      return;
    }
    if (widget.isEditing && _displayedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La prenda debe tener al menos una imagen.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      setState(() {
        _isLoadingData = false;
      });
      return;
    }

    final garmentProvider = Provider.of<GarmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProviderC>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no identificado.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() {
        _isLoadingData = false;
      });
      return;
    }

    // Preparar datos comunes
    String name = _nameController.text.trim();
    String? description =
        _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null;
    String? category = _selectedCategory;
    String size = _selectedSize!;
    String condition = _selectedCondition!;
    String? brand =
        _brandController.text.trim().isNotEmpty
            ? _brandController.text.trim()
            : null;
    String? color =
        _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null;
    String? material =
        _materialController.text.trim().isNotEmpty
            ? _materialController.text.trim()
            : null;

    bool success = false;

    if (widget.isEditing && _garmentBeingEdited != null) {
      // --- LÓGICA DE EDITAR PRENDA ---
      List<XFile> newFilesToUpload =
          _displayedImages
              .where(
                (img) =>
                    img.type == ImageSourceType.file ||
                    img.type == ImageSourceType.webBytes,
              )
              .map((img) => img.localXFile!)
              .toList();

      List<String> existingUrlsToKeep =
          _displayedImages
              .where(
                (img) =>
                    img.type == ImageSourceType.network &&
                    !_imageUrlsToDeleteFromStorage.contains(img.networkUrl),
              )
              .map((img) => img.networkUrl!)
              .toList();

      success = await garmentProvider.updateExistingGarment(
        garmentId: _garmentBeingEdited!.id,
        name: name,
        description: description,
        category: category,
        size: size,
        condition: condition,
        brand: brand,
        color: color,
        material: material,
        newImagesToUpload: newFilesToUpload,
        imageUrlsToDeleteFromStorage: _imageUrlsToDeleteFromStorage,
        existingImageUrlsToKeep: existingUrlsToKeep,
      );
    } else {
      // --- LÓGICA DE AÑADIR NUEVA PRENDA ---
      List<XFile> imagesToUpload =
          _displayedImages
              .map(
                (img) => img.localXFile!,
              ) // Asumimos que al añadir todas son locales (XFile)
              .toList();

      success = await garmentProvider.submitNewGarment(
        name: name,
        description: description,
        category: category,
        size: size,
        condition: condition,
        brand: brand,
        color: color,
        material: material,
        images: imagesToUpload, // Pasamos los XFiles
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Prenda ${widget.isEditing ? "actualizada" : "subida"} con éxito!',
          ),
        ),
      );
      await profileProvider.refreshUserGarments(authProvider.currentUserId!);

      if (widget.isEditing) {
        final garmentDetailProvider = Provider.of<GarmentDetailProvider>(
          context,
          listen: false,
        );
        await garmentDetailProvider.fetchGarmentDetails(
          _garmentBeingEdited!.id,
        );
      }
      setState(() {
        _isLoadingData = false;
      });

      context.pop(); // Volver a la pantalla anterior
    } else {
      setState(() {
        _isLoadingData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            garmentProvider.uploadErrorMessage ??
                'Error al ${widget.isEditing ? "actualizar" : "subir"} la prenda.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final garmentDetailP = context.watch<GarmentDetailProvider>();

    final double horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final double verticalSpacing = ResponsiveUtils.verticalSpacing(context);

    // Si estamos editando y los datos se acaban de cargar (y no los teníamos en _garmentBeingEdited)
    if (widget.isEditing &&
        garmentDetailP.garment != null &&
        _garmentBeingEdited == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && garmentDetailP.garment != null) {
          setState(() {
            // Asegurar que se actualice la UI con los datos cargados
            _garmentBeingEdited = garmentDetailP.garment;
            _populateControllersAndImages(_garmentBeingEdited!);
          });
        }
      });
    }

    if (widget.isEditing && _isLoadingData && _garmentBeingEdited == null) {
      // Mostrando loader solo si estamos editando, cargando, Y aún no tenemos datos locales
      return Scaffold(
        appBar: AppBar(title: const Text("Cargando Prenda...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Si es modo edición pero _garmentBeingEdited sigue siendo null (falló la carga), muestra error
    if (widget.isEditing && _garmentBeingEdited == null && !_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Error"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            garmentDetailP.errorMessage ??
                "No se pudo cargar la prenda para editar.",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: ResponsiveUtils.fontSize(context, baseSize: 20, maxSize: 24),
          ),
        ),
        title: Text(widget.isEditing ? "Editar Prenda " : "Añadir Prenda"),
        actions: [
          TextButton(
            onPressed: _isLoadingData ? null : _submitForm,
            child:
                _isLoadingData
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.background,
                      ),
                    )
                    : Text(
                      widget.isEditing ? "Guardar cambios" : "Subir",
                      style: TextStyle(
                        color:
                            AppColors
                                .darkGreen, // O Theme.of(context).colorScheme.primary
                        fontSize: ResponsiveUtils.fontSize(
                          context,
                          baseSize: 16,
                          maxSize: 18,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child:
            _isLoadingData
                ? Center(
                  child: Text(
                    "Se está subiendo la prenda...",
                    textAlign: TextAlign.center,
                  ),
                )
                : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding * 1.5,
                    vertical: verticalSpacing * 1.5,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seccion de imagenes
                        Text(
                          "Imágenes (la primera será la principal)",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: verticalSpacing * 0.5),
                        Container(
                          height: ResponsiveUtils.fontSize(
                            context,
                            baseSize: 100,
                            maxSize: 120,
                          ), // Altura fija para el visor de imágenes
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryGreen),
                          ),
                          child:
                              _displayedImages.isEmpty
                                  ? Center(
                                    child: Text(
                                      "Añade hasta 5 imágenes",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  )
                                  : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        _displayedImages.length +
                                        (_displayedImages.length < 5
                                            ? 1
                                            : 0), // Botón '+' si < 5 imágenes
                                    itemBuilder: (context, index) {
                                      if (index == _displayedImages.length &&
                                          _displayedImages.length < 5) {
                                        // Botón para añadir más imágenes
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: InkWell(
                                            onTap: _handleImageSelection,
                                            child: Container(
                                              width: ResponsiveUtils.fontSize(
                                                context,
                                                baseSize: 80,
                                                maxSize: 100,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey[400]!,
                                                  style: BorderStyle.solid,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.add_a_photo_outlined,
                                                color: Colors.grey[700],
                                                size: ResponsiveUtils.fontSize(
                                                  context,
                                                  baseSize: 30,
                                                  maxSize: 40,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      if (index >= _displayedImages.length) {
                                        return const SizedBox.shrink(); // Seguridad
                                      }
                                      final editableImage =
                                          _displayedImages[index];

                                      // Miniatura de imagen seleccionada
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Stack(
                                          clipBehavior:
                                              Clip.none, // Para que el botón de borrar se vea fuera
                                          children: [
                                            Container(
                                              width: ResponsiveUtils.fontSize(
                                                context,
                                                baseSize: 80,
                                                maxSize: 100,
                                              ),
                                              height: ResponsiveUtils.fontSize(
                                                context,
                                                baseSize: 80,
                                                maxSize: 100,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                image:
                                                    editableImage.type ==
                                                                ImageSourceType
                                                                    .network &&
                                                            editableImage
                                                                    .networkUrl !=
                                                                null
                                                        ? DecorationImage(
                                                          image:
                                                              CachedNetworkImageProvider(
                                                                editableImage
                                                                    .networkUrl!,
                                                              ),
                                                          fit: BoxFit.cover,
                                                        )
                                                        : (editableImage.type ==
                                                                    ImageSourceType
                                                                        .file &&
                                                                editableImage
                                                                        .localXFile !=
                                                                    null &&
                                                                !kIsWeb
                                                            ? DecorationImage(
                                                              image: FileImage(
                                                                File(
                                                                  editableImage
                                                                      .localXFile!
                                                                      .path,
                                                                ),
                                                              ),
                                                              fit: BoxFit.cover,
                                                            )
                                                            : (editableImage.type ==
                                                                        ImageSourceType
                                                                            .webBytes &&
                                                                    editableImage
                                                                            .webBytes !=
                                                                        null &&
                                                                    kIsWeb
                                                                ? DecorationImage(
                                                                  image: MemoryImage(
                                                                    editableImage
                                                                        .webBytes!,
                                                                  ),
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                )
                                                                : null // Placeholder si es un tipo no esperado o datos faltantes
                                                                )),
                                                color:
                                                    (editableImage
                                                                .displaySource ==
                                                            null)
                                                        ? Colors.grey[200]
                                                        : null,
                                              ),
                                              child:
                                                  (editableImage
                                                              .displaySource ==
                                                          null)
                                                      ? Center(
                                                        child: Icon(
                                                          Icons.hourglass_empty,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      )
                                                      : null,
                                            ),

                                            Positioned(
                                              top: -10,
                                              right: -10,
                                              child: InkWell(
                                                onTap:
                                                    () => _removeImage(index),
                                                child: CircleAvatar(
                                                  radius:
                                                      ResponsiveUtils.fontSize(
                                                        context,
                                                        baseSize: 12,
                                                        maxSize: 14,
                                                      ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size:
                                                        ResponsiveUtils.fontSize(
                                                          context,
                                                          baseSize: 14,
                                                          maxSize: 16,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                        ),
                        if (_displayedImages
                            .isEmpty) // Botón principal para añadir si no hay ninguna imagen aún
                          Padding(
                            padding: EdgeInsets.only(
                              top: verticalSpacing * 0.75,
                            ),
                            child: Center(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.add_photo_alternate_outlined),
                                label: Text("Añadir Fotos"),
                                onPressed: _handleImageSelection,
                                style: ElevatedButton.styleFrom(
                                  // backgroundColor: Theme.of(context).colorScheme.secondary, // Usa tu color secundario
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: verticalSpacing * 1.5),
                        // --- CAMPOS DEL FORMULARIO ---
                        _buildTextField(
                          label: "Nombre de la prenda*",
                          controller: _nameController,
                          hint: "Ej: Camisa de flores vintage",
                        ),
                        _buildTextField(
                          label: "Descripción",
                          controller: _descriptionController,
                          hint: "Detalles sobre la prenda, tejido, historia...",
                          maxLines: 3,
                        ),
                        _buildDropdownField(
                          label: "Categoría",
                          value: _selectedCategory,
                          items: _categories,
                          hint: "Selecciona categoría",
                          onChanged:
                              (val) => setState(() => _selectedCategory = val),
                        ),
                        _buildDropdownField(
                          label: "Talla*",
                          value: _selectedSize,
                          items: _sizes,
                          hint: "Selecciona talla",
                          onChanged:
                              (val) => setState(() => _selectedSize = val),
                          validator:
                              (val) => val == null ? "Campo requerido" : null,
                        ),
                        _buildDropdownField(
                          label: "Condición*",
                          value: _selectedCondition,
                          items: _conditions,
                          hint: "Selecciona condición",
                          onChanged:
                              (val) => setState(() => _selectedCondition = val),
                          validator:
                              (val) => val == null ? "Campo requerido" : null,
                        ),
                        _buildTextField(
                          label: "Marca (Opcional)",
                          controller: _brandController,
                          hint: "Ej: Zara, Adidas...",
                        ),
                        _buildTextField(
                          label: "Color principal (Opcional)",
                          controller: _colorController,
                          hint: "Ej: Azul marino",
                        ),
                        _buildTextField(
                          label: "Material (Opcional)",
                          controller: _materialController,
                          hint: "Ej: Algodón, Poliéster...",
                        ),

                        SizedBox(height: verticalSpacing * 2),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.verticalSpacing(context) * 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.darkGreen,
              fontSize: ResponsiveUtils.fontSize(
                context,
                baseSize: 14,
                maxSize: 16,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 0.4),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator:
                validator ??
                (value) {
                  // Validador por defecto para campos obligatorios (si el label tiene *)
                  if (label.endsWith('*') && (value == null || value.isEmpty)) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }

  // --- Widget Helper para DropdownButtonFormField ---
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.verticalSpacing(context) * 0.7,
        //horizontal: ResponsiveUtils.horizontalPadding(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.darkGreen,
              fontSize: ResponsiveUtils.fontSize(
                context,
                baseSize: 14,
                maxSize: 16,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 0.4),
          DropdownButtonFormField<String>(
            dropdownColor: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(8),
            decoration: InputDecoration(hintText: hint, isDense: true),
            value: value,
            menuMaxHeight: 200,
            items:
                items.map((String itemValue) {
                  return DropdownMenuItem<String>(
                    value: itemValue,
                    child: Text(
                      itemValue,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(
                          context,
                          baseSize: 14,
                          maxSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
            validator:
                validator ??
                (val) {
                  // Validador por defecto para campos obligatorios (si el label tiene *)
                  if (label.endsWith('*') && val == null) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }
}

enum ImageSourceType { network, file, webBytes }

class EditableImage {
  final String? id; // Para identificarlo, podría ser la URL o el path del XFile
  final ImageSourceType type;
  final String? networkUrl; // Si es una imagen existente
  final XFile? localXFile; // Si es una nueva imagen seleccionada
  final Uint8List?
  webBytes; // Si es una nueva imagen de web (para previsualización)

  EditableImage.network(this.networkUrl)
    : type = ImageSourceType.network,
      localXFile = null,
      webBytes = null,
      id = networkUrl;

  EditableImage.file(this.localXFile)
    : type = ImageSourceType.file,
      networkUrl = null,
      webBytes = null,
      id = localXFile?.path; // O localXFile.name para web

  EditableImage.web(
    this.localXFile,
    this.webBytes,
  ) // localXFile para metadata, webBytes para mostrar
  : type = ImageSourceType.webBytes,
      networkUrl = null,
      id = localXFile?.path; // O localXFile.name

  // Getter para facilitar la visualización
  dynamic get displaySource {
    if (type == ImageSourceType.network) return networkUrl;
    if (type == ImageSourceType.file) {
      return File(localXFile!.path); // ¡Cuidado con web!
    }
    if (type == ImageSourceType.webBytes) return webBytes;
    return null;
  }
}
