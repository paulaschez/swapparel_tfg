import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swapparel/app/config/constants/firestore_user_fields.dart';

class UserModel {
  final String id; // Corresponde al document ID (Firebase Auth UID)
  final String email; // Correo electrónico del usuario
  final String name; // Nombre real y que se mostrara
  final String username; // @handle unico, inicialmente generado
  String? photoUrl; // URL de la foto de perfil
  String? location; // Ubicacion
  Timestamp createdAt; // Cuando se creo el perfil
  final int successfulSwaps; // Número de intercambios completados
  final int ratingCount;     // Número total de valoraciones recibidas
  final double averageRating;  // Promedio de valoración (ej: de 0 a 5)


  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.username,
    this.location,
    this.photoUrl,
    required this.createdAt,
    this.successfulSwaps = 0, // Valor por defecto
    this.ratingCount = 0,     // Valor por defecto
    this.averageRating = 0.0, // Valor por defecto
  });

   String get displayName => name;
  String get atUsernameHandle => '@$username';

  // Método para convertir un UserModel a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      emailField: email,
      nameField: name,
      usernameField: username,
      photoUrlField: photoUrl,
      locationField: location,
      createdAtField: createdAt,
      swapCountField: successfulSwaps,
      ratingCountField: ratingCount,
      averageRatingField: averageRating,
    };
  }

  // Método Factory para crear un UserModel desde un DocumentSnapshot de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for UserModel id: ${doc.id}');
    }

    return UserModel(
      id: doc.id,
      email: data[emailField],
      name: data[nameField],
      username: data[usernameField],
      photoUrl: data[photoUrlField],
      createdAt: data[createdAtField],
      location: data[locationField],
      successfulSwaps: data[swapCountField] ?? 0, 
      ratingCount: data[ratingCountField] ?? 0, 
      averageRating: (data[averageRatingField] ?? 0.0).toDouble()
    );
  }
}
