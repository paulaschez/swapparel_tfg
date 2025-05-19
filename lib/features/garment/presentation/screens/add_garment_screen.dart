import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/garment/presentation/provider/garment_provider.dart';
import 'package:swapparel/features/profile/presentation/provider/profile_provider.dart';
import '../../../../app/config/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'package:image_picker/image_picker.dart';

class AddGarmentScreen extends StatefulWidget {
  const AddGarmentScreen({super.key});

  @override
  State<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends State<AddGarmentScreen> {
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
  List<File> _selectedImages = [];

  // TODO: Definir Enums para opciones de Dropdown
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

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  // --- Función para mostrar opciones al añadir prenda ---
  void _showImagePickerOptions() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Subir de la galería'),
                onTap: () {
                  _pickImageFromGallery();
                  print('Seleccionar de galería');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto'),
                onTap: () {
                  _takePictureWithCamera();
                  print('Tomar foto');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Seleccionar foto desde la galeria
  Future<void> _pickImageFromGallery() async {
    try {
      // TODO: Implementar seleccion multiple de imagenes
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      _addPhoto(pickedFile);
    } catch (e) {
      // Manejar errores (ej: permiso denegado)
      print("Error al seleccionar imagen de galería: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _addPhoto(XFile? pickedPhoto) {
    if (pickedPhoto != null) {
      if (_selectedImages.length < 5) {
        setState(() {
          _selectedImages.add(File(pickedPhoto.path));
        });
      } else {
        // Mostrar mensaje de que ya se alcanzo el limite
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

  Future<void> _takePictureWithCamera() async {
    try {
      final XFile? takenPicture = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      _addPhoto(takenPicture);
    } catch (e) {
      print("Error al tomar foto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al usar la cámara: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitGarment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, añade al menos una imagen.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
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

      bool success = await garmentProvider.submitNewGarment(
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
        category: _selectedCategory!,
        size: _selectedSize,
        condition: _selectedCondition!,
        brand:
            _brandController.text.trim().isNotEmpty
                ? _brandController.text.trim()
                : null,
        color:
            _colorController.text.trim().isNotEmpty
                ? _colorController.text.trim()
                : null,
        material:
            _materialController.text.trim().isNotEmpty
                ? _materialController.text.trim()
                : null,
        images: _selectedImages,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Prenda subida con éxito!')),
        );
        await profileProvider.refreshUserGarments(authProvider.currentUserId!);
        context.pop();
        print(
          "Subir Prenda: Nombre: ${_nameController.text}, Categoría: $_selectedCategory, Imágenes: ${_selectedImages.length}",
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              garmentProvider.uploadErrorMessage ?? 'Error al subir la prenda.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final double verticalSpacing = ResponsiveUtils.verticalSpacing(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: ResponsiveUtils.fontSize(context, baseSize: 20, maxSize: 24),
          ),
        ),
        title: Text("Añadir Prenda"),
        actions: [
          TextButton(
            onPressed: _submitGarment, // Llama al método de subida
            child: Text(
              "Subir",
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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
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
                    _selectedImages.isEmpty
                        ? Center(
                          child: Text(
                            "Añade hasta 5 imágenes",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              _selectedImages.length +
                              (_selectedImages.length < 5
                                  ? 1
                                  : 0), // Botón '+' si < 5 imágenes
                          itemBuilder: (context, index) {
                            if (index == _selectedImages.length &&
                                _selectedImages.length < 5) {
                              // Botón para añadir más imágenes
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: _showImagePickerOptions,
                                  child: Container(
                                    width: ResponsiveUtils.fontSize(
                                      context,
                                      baseSize: 80,
                                      maxSize: 100,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
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
                            if (index >= _selectedImages.length) {
                              return const SizedBox.shrink(); // Seguridad
                            }

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
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(
                                          _selectedImages[index],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: InkWell(
                                      onTap: () => _removeImage(index),
                                      child: CircleAvatar(
                                        radius: ResponsiveUtils.fontSize(
                                          context,
                                          baseSize: 12,
                                          maxSize: 14,
                                        ),
                                        backgroundColor: Colors.redAccent,
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: ResponsiveUtils.fontSize(
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
              if (_selectedImages
                  .isEmpty) // Botón principal para añadir si no hay ninguna imagen aún
                Padding(
                  padding: EdgeInsets.only(top: verticalSpacing * 0.75),
                  child: Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.add_photo_alternate_outlined),
                      label: Text("Añadir Fotos"),
                      onPressed: _showImagePickerOptions,
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
                label: "Categoría*",
                value: _selectedCategory,
                items: _categories,
                hint: "Selecciona categoría",
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? "Campo requerido" : null,
              ),
              _buildDropdownField(
                label: "Talla",
                value: _selectedSize,
                items: _sizes,
                hint: "Selecciona talla (opcional)",
                onChanged: (val) => setState(() => _selectedSize = val),
              ),
              _buildDropdownField(
                label: "Condición*",
                value: _selectedCondition,
                items: _conditions,
                hint: "Selecciona condición",
                onChanged: (val) => setState(() => _selectedCondition = val),
                validator: (val) => val == null ? "Campo requerido" : null,
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
            decoration: InputDecoration(hintText: hint, isDense: true),
            value: value,
            isExpanded: true,
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
