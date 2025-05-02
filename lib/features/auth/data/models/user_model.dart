import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // Corresponde al document ID (Firebase Auth UID)
  final String email; // Correo electrónico del usuario
  final String name; // Nombre de usuario
  final String? displayName; // Nombre que se mostrará
  final String? photoUrl; // URL de la foto de perfil

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.displayName,
    this.photoUrl,
  });

  // Método para convertir un UserModel a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      'E-mail': email, 
      'name': name,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  // Método Factory para crear un UserModel desde un DocumentSnapshot de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      // Manejar el caso donde el documento no existe o no tiene datos
       throw StateError('Missing data for UserModel id: ${doc.id}');
    }

    return UserModel(
      id: doc.id, 
      email: data['E-mail'], 
      name: data['name'], 
      displayName: data['displayName'], 
      photoUrl: data['photoUrl'], 
    );
  }

   // (Opcional) Método Factory para crear desde un Map genérico (útil si no tienes el DocumentSnapshot)
    factory UserModel.fromJson(Map<String, dynamic> data, String id) {
     return UserModel(
       id: id,
       email: data['E-mail'] ?? '',
       name: data['name'],
       displayName: data['displayName'],
       photoUrl: data['photoUrl'],
     );
   }
}