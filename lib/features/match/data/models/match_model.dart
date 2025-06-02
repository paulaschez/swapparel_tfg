import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus { active, offerMade, completed }

class MatchModel {
  final String id; // ID del documento de match en Firestore
  final List<String>
  participantIds; // Lista con los dos UserIDs [userId1, userId2]
  final Map<String, String>
  matchedItems; //{ userId1: garmentIdDe1, userId2: garmentIdDe2 }
  final Timestamp createdAt;
  final Timestamp?
  lastActivityAt; // Para ordenar chats/matches por actividad reciente
  final Map<String, int> unreadCounts;
  final String? lastMessageSnippet;
  final Map<String, Map<String, String?>>? participantDetails;
  final MatchStatus matchStatus;
  final String?
  offerIdThatCompletedMatch; // ID de la oferta que completó este match
  final Map<String, bool> hasUserRated; // { userId: true/false }

  MatchModel({
    required this.id,
    required this.participantIds,
    required this.matchedItems,
    required this.createdAt,
    this.lastActivityAt,
    this.lastMessageSnippet,
    this.unreadCounts = const {},
    this.matchStatus = MatchStatus.active,
    this.participantDetails,
    this.offerIdThatCompletedMatch,
    this.hasUserRated = const {},
  }) {
    participantIds.sort();
  }

  factory MatchModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MatchModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      matchedItems: Map<String, String>.from(data['matchedItems'] ?? {}),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastActivityAt: data['lastActivityAt'],
      lastMessageSnippet: data['lastMessageSnippet'],
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      participantDetails: (data['participantDetails'] as Map<String, dynamic>?)
          ?.map(
            (key, value) =>
                MapEntry(key, Map<String, String?>.from(value as Map)),
          ),
      matchStatus: MatchStatus.values.firstWhere(
        (e) => e.toString() == data['matchStatus'],
        orElse: () => MatchStatus.active,
      ),
      offerIdThatCompletedMatch: data['offerIdThatCompletedMatch'],
      hasUserRated: Map<String, bool>.from(data['hasUserRated'] ?? {}),
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
      'matchStatus': matchStatus.toString(),
      'offerIdThatCompletedMatch': offerIdThatCompletedMatch,
      'hasUserRated': hasUserRated,
    };
  }

  MatchModel copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, String>? matchedItems,
    Timestamp? createdAt,
    Timestamp?
    lastActivityAt, 
    Map<String, int>? unreadCounts,
    String? lastMessageSnippet, 
    Map<String, Map<String, String?>>? participantDetails, 
    MatchStatus? matchStatus,
    String? offerIdThatCompletedMatch, 
    Map<String, bool>? hasUserRated,
  }) {

    List<String>? sortedParticipantIds =
        participantIds != null ? (List.from(participantIds)..sort()) : null;

    return MatchModel(
      id: id ?? this.id,
      participantIds:
          participantIds ?? sortedParticipantIds ?? this.participantIds,
      matchedItems: matchedItems ?? this.matchedItems,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastMessageSnippet: lastMessageSnippet ?? this.lastMessageSnippet,
      participantDetails: participantDetails ?? this.participantDetails,
      matchStatus: matchStatus ?? this.matchStatus,
      offerIdThatCompletedMatch:
          offerIdThatCompletedMatch ?? this.offerIdThatCompletedMatch,
      hasUserRated: hasUserRated ?? this.hasUserRated,
    );
  }

  // Helper para generar un ID de documento de match consistente si no usas auto-ID
  static String generateMatchId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Ordenar para que user1_user2 sea igual a user2_user1
    return ids.join('_');
  }
}
