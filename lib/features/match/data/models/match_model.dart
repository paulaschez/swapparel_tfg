import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id; // ID del documento de match en Firestore
  final List<String> participantIds; // Lista con los dos UserIDs [userId1, userId2]
  final Map<String, String> matchedItems; // Opcional: { userId1: garmentIdDe1, userId2: garmentIdDe2 }
                                       // Para saber qué prendas específicas iniciaron el match,
                                       // aunque el chat podría ser genérico entre los usuarios.
  final Timestamp createdAt;
  final Timestamp? lastActivityAt; // Para ordenar chats/matches por actividad reciente

  MatchModel({
    required this.id,
    required this.participantIds,
    required this.matchedItems,
    required this.createdAt,
    this.lastActivityAt,
  }) {
    // Asegurar que participantIds siempre esté ordenado para generar IDs de match consistentes
    // si decides crear IDs de match basados en los UIDs de los participantes.
    // participantIds.sort(); // Comentado por ahora, el ID del doc puede ser autogenerado
  }

  factory MatchModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MatchModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      // Convertir el Map de Firestore a Map<String, String>
      matchedItems: Map<String, String>.from(data['matchedItems'] ?? {}),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastActivityAt: data['lastActivityAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantIds': participantIds,
      'matchedItems': matchedItems,
      'createdAt': createdAt,
      'lastActivityAt': lastActivityAt ?? createdAt, // Inicializar con createdAt
    };
  }

  // Helper para generar un ID de documento de match consistente si no usas auto-ID
  // static String generateMatchId(String userId1, String userId2) {
  //   List<String> ids = [userId1, userId2];
  //   ids.sort(); // Ordenar para que user1_user2 sea igual a user2_user1
  //   return ids.join('_');
  // }
}