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
  final int swapCount; // Número de intercambios completados
  final int numberOfRatings; // Número total de valoraciones recibidas
  final double? totalRatingStars; // Estrellas totales
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.username,
    this.location,
    this.photoUrl,
    required this.createdAt,
    this.swapCount = 0, // Valor por defecto
    this.numberOfRatings = 0, // Valor por defecto
    this.totalRatingStars, // Valor por defecto
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
      swapCountField: swapCount,
      numberOfRatingsField: numberOfRatings,
      totalRatingStarsField: totalRatingStars,
    };
  }

  // Método Factory para crear un UserModel desde un DocumentSnapshot de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for UserModel id: ${doc.id}');
    }
    print('UserModel.fromFirestore - Data for ${doc.id}:');
    print('email: ${data[emailField]} (${data[emailField]?.runtimeType})');
    print('name: ${data[nameField]} (${data[nameField]?.runtimeType})');
    print(
      'createdAt: ${data[createdAtField]} (${data[createdAtField]?.runtimeType})',
    );
    print(
      'swapCount: ${data[swapCountField]} (${data[swapCountField]?.runtimeType})',
    );
    print(
      'totalRatingStars: ${data[totalRatingStarsField]} (${data[totalRatingStarsField]?.runtimeType})',
    );
    print(
      'numberOfRatings: ${data[numberOfRatingsField]} (${data[numberOfRatingsField]?.runtimeType})',
    );

    return UserModel(
      id: doc.id,
      email: data[emailField],
      name: data[nameField],
      username: data[usernameField],
      photoUrl: data[photoUrlField],
      createdAt: data[createdAtField],
      location: data[locationField],
      swapCount: data[swapCountField] ?? 0,
      totalRatingStars: data[totalRatingStarsField] ?? 0.0,
      numberOfRatings: data[numberOfRatingsField] ?? 0,
    );
  }

  // Getter para la media de valoración
  double get averageRating {
    if (numberOfRatings == 0) {
      return 0.0;
    }
    return totalRatingStars! / numberOfRatings; // double / int da double
  }
}
 