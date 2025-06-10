import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swapparel/core/constants/firestore_garment_fields.dart';

class GarmentModel {
  final String id; // ID del documento de la prenda en Firestore
  final String ownerId; // UID del usuario propietario
  final String
  ownerUsername; // Username del propietario (para mostrar en la tarjeta)
  final String? ownerPhotoUrl; // URL de la foto del propietario (opcional)
  final String name; // Nombre/Título de la prenda
  final String?
  description; // Descripción detallada (más para la pantalla de detalle)
  final List<String> imageUrls; // Lista de URLs de las imágenes de la prenda
  final String size; // Talla
  final String condition; // Condición (Como nuevo, Buen estado, etc.)
  final String? category; // Categoría (Camisa, Pantalón, etc.)
  final String? brand; // Marca (Opcional)
  final String? color; // Color (Opcional)
  final String? material; // Material (Opcional)
  final Timestamp createdAt; // Cuándo se subió la prenda
  final Timestamp updateAt; // Cuándo se editó la prenda
  final bool isAvailable;

  GarmentModel({
    required this.id,
    required this.ownerId,
    required this.ownerUsername,
    this.ownerPhotoUrl,
    required this.name,
    this.description,
    required this.imageUrls,
    required this.size,
    required this.condition,
    this.category,
    this.brand,
    this.color,
    this.material,
    required this.createdAt,
    required this.isAvailable,
    required this.updateAt,
  });

  // Factory para crear desde un DocumentSnapshot de Firestore
  factory GarmentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for GarmentModel id: ${doc.id}');
    }

    return GarmentModel(
      id: doc.id,
      ownerId: data[ownerIdField] ?? '',
      ownerUsername: data[ownerUsernameField] ?? 'Usuario Desconocido',
      ownerPhotoUrl: data[ownerPhotoUrlField],
      name: data[nameField] ?? 'Sin Nombre',
      description: data[descripctionField],
      imageUrls: List<String>.from(data[imageUrlsField] ?? []),
      size: data[sizeField],
      condition: data[conditionField],
      category: data[categoryField],
      brand: data[brandField],
      color: data[colorField],
      material: data[materialField],
      createdAt: data[createdAtField],
      isAvailable: data[isAvailableField],
      updateAt: data[updatedAtField],
    );
  }

  // Método para convertir a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      ownerIdField: ownerId,
      ownerUsernameField: ownerUsername,
      ownerPhotoUrlField: ownerPhotoUrl,
      nameField: name,
      descripctionField: description,
      imageUrlsField: imageUrls,
      sizeField: size,
      conditionField: condition,
      categoryField: category,
      brandField: brand,
      colorField: color,
      materialField: material,
      createdAtField: createdAt,
      isAvailableField: isAvailable,
      updatedAtField: updateAt,
    };
  }
}
