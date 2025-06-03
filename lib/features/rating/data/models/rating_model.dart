import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id; // ID del documento de la valoración
  final String matchId; // ID del match al que pertenece esta valoración
  final String offerId; // ID de la oferta que completó el match
  final String ratingUserId; // ID del usuario que HACE la valoración
  final String ratedUserId;  // ID del usuario que ES VALORADO
  final String? ratingUserName;
  final String? ratedUserName;
  final double stars;
  final String? comment; // Comentario opcional
  final Timestamp createdAt;

  RatingModel({
    required this.id,
    required this.matchId,
    required this.offerId,
    required this.ratingUserId,
    required this.ratedUserId,
    required this.stars,
    this.comment,
    required this.createdAt,
    this.ratedUserName,
    this.ratingUserName,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return RatingModel(
      id: doc.id,
      matchId: data['matchId'] ?? '',
      offerId: data['offerId'] ?? '',
      ratingUserId: data['ratingUserId'] ?? '',
      ratedUserId: data['ratedUserId'] ?? '',
      stars: (data['stars'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      ratedUserName: data['ratingUserName'] as String?,
      ratingUserName: data['ratingUserName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'offerId': offerId,
      'ratingUserId': ratingUserId,
      'ratedUserId': ratedUserId,
      'stars': stars,
      'comment': comment,
      'createdAt': createdAt,
      'ratedUserName' : ratedUserName,
      'ratingUserName' : ratingUserName
    };
  }
}