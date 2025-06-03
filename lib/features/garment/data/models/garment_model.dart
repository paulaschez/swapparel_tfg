import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? size; // Talla
  final String? condition; // Condición (Como nuevo, Buen estado, etc.)
  final String? category; // Categoría (Camisa, Pantalón, etc.)
  final String? brand; // Marca (Opcional)
  final String? color; // Color (Opcional)
  final String? material; // Material (Opcional)

  final Timestamp createdAt; // Cuándo se subió la prenda
  final bool isAvailable;
  // campos location (para filtros de distancia)?

  GarmentModel({
    required this.id,
    required this.ownerId,
    required this.ownerUsername,
    this.ownerPhotoUrl,
    required this.name,
    this.description,
    required this.imageUrls,
    this.size,
    this.condition,
    this.category,
    this.brand,
    this.color,
    this.material,
    required this.createdAt,
    required this.isAvailable,
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
      ownerId: data['ownerId'] ?? '',
      ownerUsername: data['ownerUsername'] ?? 'Usuario Desconocido',
      ownerPhotoUrl: data['ownerPhotoUrl'],
      name: data['name'] ?? 'Sin Nombre',
      description: data['description'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      size: data['size'],
      condition: data['condition'],
      category: data['category'],
      brand: data['brand'],
      color: data['color'],
      material: data['material'],
      createdAt: data['createdAt'],
      isAvailable: data['isAvailable'], 
    );
  }

  // Método para convertir a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'ownerUsername': ownerUsername,
      'ownerPhotoUrl': ownerPhotoUrl,
      'name': name,
      'description': description,
      'imageUrls': imageUrls,
      'size': size,
      'condition': condition,
      'category': category,
      'brand': brand,
      'color': color,
      'material': material,
      'createdAt': createdAt,
      'isAvailable': isAvailable,
    };
  }
}
