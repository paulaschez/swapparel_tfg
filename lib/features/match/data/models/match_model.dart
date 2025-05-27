import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id; // ID del documento de match en Firestore
  final List<String>
  participantIds; // Lista con los dos UserIDs [userId1, userId2]
  final Map<String, String>
  matchedItems; // Opcional: { userId1: garmentIdDe1, userId2: garmentIdDe2 }
  // Para saber qué prendas específicas iniciaron el match,
  // aunque el chat podría ser genérico entre los usuarios.
  final Timestamp createdAt;
  final Timestamp?
  lastActivityAt; // Para ordenar chats/matches por actividad reciente
  final Map<String, int> unreadCounts;
  final String? lastMessageSnippet;
  final Map<String, Map<String, String?>>? participantDetails;

  MatchModel({
    required this.id,
    required this.participantIds,
    required this.matchedItems,
    required this.createdAt,
    this.lastActivityAt,
    this.lastMessageSnippet, // Asegúrate de que este campo exista
    this.unreadCounts = const {}, // Valor por defecto: mapa vacío
    this.participantDetails,
  }) {
    participantIds.sort();
  }

  factory MatchModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // --- Conversión para matchedItems ---
    Map<String, String> tempMatchedItems = {};
    if (data['matchedItems'] != null && data['matchedItems'] is Map) {
      (data['matchedItems'] as Map).forEach((key, value) {
        if (key is String && value is String) {
          // Asegurarse de los tipos
          tempMatchedItems[key] = value;
        }
      });
    }

    // --- Conversión para participantDetails ---
    Map<String, Map<String, String?>> tempParticipantDetails = {};
    if (data['participantDetails'] != null &&
        data['participantDetails'] is Map) {
      (data['participantDetails'] as Map).forEach((userIdKey, userDetailsMap) {
        if (userIdKey is String && userDetailsMap is Map) {
          Map<String, String?> details = {};
          // Iterar sobre el mapa interno de detalles del participante
          (userDetailsMap).forEach((detailKey, detailValue) {
            if (detailKey is String) {
              // El valor puede ser String o null
              details[detailKey] = detailValue as String?;
            }
          });
          tempParticipantDetails[userIdKey] = details;
        }
      });
    }
    return MatchModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      // Convertir el Map de Firestore a Map<String, String>
      matchedItems: tempMatchedItems,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastActivityAt: data['lastActivityAt'],
      lastMessageSnippet: data['lastMessageSnippet'] ?? '',
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      participantDetails: tempParticipantDetails,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantIds': participantIds,
      'matchedItems': matchedItems,
      'createdAt': createdAt,
      'lastActivityAt':
          lastActivityAt ?? createdAt, // Inicializar con createdAt
      'lastMessageSnippet': lastMessageSnippet,
      'unreadCounts': unreadCounts,
      'participantDetails': participantDetails,
    };
  }

  // Helper para generar un ID de documento de match consistente si no usas auto-ID
  static String generateMatchId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Ordenar para que user1_user2 sea igual a user2_user1
    return ids.join('_');
  }
}
